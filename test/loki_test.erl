-module(loki_test).

-include_lib("eunit/include/eunit.hrl").


loki_test_() ->
    {setup, fun setup/0, fun teardown/1,
     [
      {"Simple run",         fun simple_run/0},
      {"Fold",               fun fold/0},
      {"List import export", fun list_import_export/0}
     ]}.

-define(OPTIONS, [{backend, loki_backend_rocksdb}]).

setup() ->
    application:start(loki).

teardown(_) ->
    application:stop(loki).

simple_run() ->
    {ok, Store} = loki:start(test_kv, [], ?OPTIONS),
    Key = key,
    Value = 1,

    ok = loki:put(Store, Key, Value),
    {ok, ReceivedValue1} = loki:get(Store, Key),

    ?assertEqual(Value, ReceivedValue1),
    ?assertEqual({error, not_found}, loki:get(Store, unknown_key)),

    ok = loki:update(Store, Key, fun(_K, V) -> V + 1 end),
    {ok, ReceivedValue2} = loki:get(Store, Key),
    ?assertEqual(Value + 1, ReceivedValue2),

    ok = loki:update_value(Store, Key, 100, fun(_K, OldV, NewV) -> OldV + NewV  end),
    {ok, ReceivedValue3} = loki:get(Store, Key),
    ?assertEqual(Value + 101, ReceivedValue3),

    ok = loki:destroy(Store).

fold() ->
    {ok, Store} = loki:start(test_kv, [], ?OPTIONS),

    [loki:put(Store, E, E) || E <- lists:seq(1, 100)],

    Sum = loki:fold(Store, fun(_K, V, Acc) -> Acc + V end, 0),

    ?assertEqual(100 * 101 div 2, Sum),

    ok = loki:destroy(Store).

list_import_export() ->
    {ok, Store} = loki:start(test_kv, [], ?OPTIONS),

    List = [{E, E} || E <- lists:seq(1, 100)],

    ok = loki:from_list(Store, List),

    ResultList = loki:to_list(Store),

    ?assertEqual(List, lists:sort(ResultList)),

    ok = loki:destroy(Store).
