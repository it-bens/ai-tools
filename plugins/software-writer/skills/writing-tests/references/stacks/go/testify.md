# Go: testify

Table construct: a struct slice of cases, each run as a `t.Run` subtest with testify assertions in the body; inside a `suite.Suite` method the subtest call is `s.Run`.
