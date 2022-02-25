%% File generated by erl-openapi on "2022-02-25T12:01:17Z".

-module(stripe_openapi).

-export_type([info/0, contact/0, license/0, server/0]).

-export([info/0, servers/0]).

-type info() ::
    #{title := binary(),
      description => binary(),
      termsOfService => binary(),
      contact => contact(),
      license => license(),
      version := binary()}.
-type contact() ::
    #{name => binary(),
      url => binary(),
      email => binary()}.
-type license() :: #{name := binary(), url => binary()}.
-type server() ::
    #{url := binary(),
      description => binary(),
      variables => #{binary() := server_variable()}}.
-type server_variable() ::
    #{enum => [binary()],
      default := binary(),
      description => binary()}.

-spec info() -> info().
info() ->
    #{contact =>
          #{email => <<"dev-platform@stripe.com">>,
            name => <<"Stripe Dev Platform Team">>,
            url => <<"https://stripe.com">>},
      description =>
          <<"The Stripe REST API. Please see https://stripe.com/docs/api for more details.">>,
      termsOfService => <<"https://stripe.com/us/terms/">>,
      title => <<"Stripe API">>,
      version => <<"2020-08-27">>,
      <<"x-stripeSpecFilename">> => <<"spec3">>}.

-spec servers() -> [server()].
servers() ->
    [#{url => <<"https://api.stripe.com/">>}].
