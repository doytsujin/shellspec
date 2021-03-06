#shellcheck shell=sh disable=SC2016

Describe "libexec/translator.sh"
  Include "$SHELLSPEC_LIB/libexec/translator.sh"

  Describe "check_filter()"
    Context 'when no description'
      It 'returns failure'
        When run check_filter ""
        The status should be failure
      End
    End

    Context 'when description only'
      BeforeRun 'SHELLSPEC_TAG_FILTER='

      It 'returns failure when not match pattern'
        BeforeRun SHELLSPEC_EXAMPLE_FILTER="dummy"
        When run check_filter "test"
        The status should be failure
      End

      It 'returns success when match pattern'
        BeforeRun SHELLSPEC_EXAMPLE_FILTER="foo*"
        When run check_filter "foobar"
        The status should be success
      End

      It 'does not match tag'
        BeforeRun SHELLSPEC_TAG_FILTER=",tag,"
        When run check_filter "desc"
        The status should be failure
      End

      It 'does not cause an error use the variable'
        BeforeRun 'unset no_such_variable ||:'
        When run check_filter '"desc $no_such_variable"'
        The status should be failure
      End
    End

    Context 'when tag exists'
      BeforeRun 'SHELLSPEC_EXAMPLE_FILTER='

      Context 'when specified tag has no value'
        It 'returns failure when not match tag'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag,"
          When run check_filter "desc TAG"
          The status should be failure
        End

        It 'returns success when match tag'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag,"
          When run check_filter "desc tag"
          The status should be success
        End

        It 'returns success when match any tag'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag1,tag2,"
          When run check_filter "desc tag2"
          The status should be success
        End

        It 'matches tag with value'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag,"
          When run check_filter "desc tag:value"
          The status should be success
        End
      End

      Context 'when specified tag has a value'
        It 'returns success when match tag'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag:value,"
          When run check_filter "desc tag:value"
          The status should be success
        End

        It 'does not match tag with different value'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag:value1,"
          When run check_filter "desc tag:value2"
          The status should be failure
        End

        It 'does not matches tag without value'
          BeforeRun SHELLSPEC_TAG_FILTER=",tag:value,"
          When run check_filter "desc tag"
          The status should be failure
        End
      End
    End
  End

  Describe "escape_one_line_syntax()"
    It 'escapes $ and `'
      When call escape_one_line_syntax desc '$foo `bar`'
      The variable desc should eq '\$foo \`bar\`'
    End

    It 'escapes $ and ` inside of double qoute'
      When call escape_one_line_syntax desc '"$foo" `bar`'
      The variable desc should eq '"\$foo" \`bar\`'
    End

    It 'does not escape $ inside of single quote'
      When call escape_one_line_syntax desc "'\$foo' bar"
      The variable desc should eq "'\$foo' bar"
    End

    It 'does not escape meta character'
      When call escape_one_line_syntax desc "var[2] * ? \\ end"
      The variable desc should eq "var[2] * ? \\ end"
    End
  End
End
