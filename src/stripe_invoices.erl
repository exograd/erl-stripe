%% Copyright (c) 2022 Exograd SAS.
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
%% SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
%% IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(stripe_invoices).

-export([get_all/2, send/3]).

-export_type([get_all_options/0, send_data/0]).

-type get_all_options() ::
        stripe_client:get_invoices_request_query().

-type send_data() ::
        stripe_client:post_invoices_invoice_send_request_body().

-spec get_all(get_all_options(), stripe:client_options()) ->
        stripe:result([stripe_model:invoice()]).
get_all(Options, ClientOptions) ->
  get_all(Options, stripe_utils:client_options(ClientOptions), []).

-spec get_all(get_all_options(), stripe_client:options(),
               [stripe_model:invoice()]) ->
        stripe:result([stripe_model:invoice()]).
get_all(Options, ClientOptions, Acc) ->
  ReqOptions = #{query => Options},
  case stripe_client:get_invoices(ReqOptions, ClientOptions) of
    {ok, #{data := Invoices, has_more := More}, #{status := S}} when
        S >= 200, S < 300 ->
      Acc2 = [Invoices | Acc],
      case More of
        true ->
          #{id := LastId} = lists:last(Invoices),
          get_all(Options#{starting_after => LastId}, ClientOptions, Acc2);
        false ->
          {ok, lists:flatten(lists:reverse(Acc2))}
      end;
    {ok, #{error := Error}, _} ->
      {error, {api_error, Error}};
    {error, Error} ->
      {error, {client_error, Error}}
  end.

-spec send(binary(), send_data(), stripe:client_options()) ->
        stripe:result(stripe_model:invoice()).
send(InvoiceId, Data, ClientOptions) ->
  ReqOptions = #{path => #{invoice => InvoiceId},
                 body => {<<"application/x-www-form-urlencoded">>, Data}},
  ClientOptions2 = stripe_utils:client_options(ClientOptions),
  case stripe_client:post_invoices_invoice_send(ReqOptions, ClientOptions2) of
    {ok, Invoice, #{status := S}} when S >= 200, S < 300 ->
      {ok, Invoice};
    {ok, #{error := Error}, _} ->
      {error, {api_error, Error}};
    {error, Error} ->
      {error, {client_error, Error}}
  end.
