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

-module(stripe_usage_records).

-export([create/3, get_summaries/3]).

-export_type([create_data/0, get_summaries_options/0]).

-type create_data() ::
        stripe_client:post_subscription_items_subscription_item_usage_records_request_body().

-type get_summaries_options() ::
        stripe_client:get_subscription_items_subscription_item_usage_record_summaries_request_query().

-spec create(binary(), create_data(), stripe:client_options()) ->
        stripe:result(stripe_model:usage_record()).
create(SubscriptionItemId, Data, ClientOptions) ->
  ReqOptions = #{path => #{subscription_item => SubscriptionItemId},
                 body => {<<"application/x-www-form-urlencoded">>, Data}},
  ClientOptions2 = stripe_utils:client_options(ClientOptions),
  case
    stripe_client:post_subscription_items_subscription_item_usage_records(
      ReqOptions, ClientOptions2)
  of
    {ok, Record, #{status := S}} when S >= 200, S < 300 ->
      {ok, Record};
    {ok, #{error := Error}, _} ->
      {error, {api_error, Error}};
    {error, Error} ->
      {error, {client_error, Error}}
  end.

-spec get_summaries(binary(), get_summaries_options(),
                    stripe:client_options()) ->
        stripe:result([stripe_model:usage_record_summary()]).
get_summaries(SubscriptionItemId, Options, ClientOptions) ->
  get_summaries(SubscriptionItemId, Options,
                stripe_utils:client_options(ClientOptions), []).

-spec get_summaries(binary(), get_summaries_options(), stripe_client:options(),
                    [stripe_model:usage_record_summary()]) ->
        stripe:result([stripe_model:usage_record_summary()]).
get_summaries(SubscriptionItemId, Options, ClientOptions, Acc) ->
  ReqOptions = #{path => #{subscription_item => SubscriptionItemId},
                 query => Options},
  case
    stripe_client:get_subscription_items_subscription_item_usage_record_summaries(
      ReqOptions, ClientOptions)
  of
    {ok, #{data := Summaries, has_more := More}, #{status := S}} when
        S >= 200, S < 300 ->
      Acc2 = [Summaries | Acc],
      case More of
        true ->
          #{id := LastId} = lists:last(Summaries),
          get_summaries(SubscriptionItemId, Options#{starting_after => LastId},
                        ClientOptions, Acc2);
        false ->
          {ok, lists:flatten(lists:reverse(Acc2))}
      end;
    {ok, #{error := Error}, _} ->
      {error, {api_error, Error}};
    {error, Error} ->
      {error, {client_error, Error}}
  end.
