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

-module(stripe_prices).

-export([get_all/2]).

-type get_all_options() ::
        stripe_client:get_prices_request_query().

-spec get_all(get_all_options(), stripe:client_options()) ->
        stripe:result([stripe_model:price()]).
get_all(Options, ClientOptions) ->
  get_all(Options, stripe_utils:client_options(ClientOptions), []).

-spec get_all(get_all_options(), stripe_client:options(),
               [stripe_model:price()]) ->
        stripe:result([stripe_model:price()]).
get_all(Options, ClientOptions, Acc) ->
  ReqOptions = #{query => Options},
  case stripe_client:get_prices(ReqOptions, ClientOptions) of
    {ok, #{data := Prices, has_more := More}, #{status := S}} when
        S >= 200, S < 300 ->
      Acc2 = [Prices | Acc],
      case More of
        true ->
          #{id := LastId} = lists:last(Prices),
          get_all(Options#{starting_after => LastId}, ClientOptions, Acc2);
        false ->
          {ok, lists:flatten(lists:reverse(Acc2))}
      end;
    {ok, #{error := Error}, _} ->
      {error, {api_error, Error}};
    {error, Error} ->
      {error, {client_error, Error}}
  end.
