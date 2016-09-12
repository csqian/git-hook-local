#!/usr/bin/env bats
load test_helper

setup() {
  mkdir -p "$HOOK_TEST_PATH"
  cd "$HOOK_TEST_PATH"
  cp -rf "$INSTALL_SCRIPT_PATH" "$HOOK_TEST_PATH"
  chmod a+x "${HOOK_TEST_INSTALL_PATH}/git-client-hook.sh"
}

@test "git-client-hook: If no .git/ dir exist, hook will not install." {
  run git-client-hook.sh
  assert_success "No ${HOOK_TEST_PATH}/.git/hooks exist!"

  git init
  run git-client-hook.sh
  refute_output_contains "No ${HOOK_TEST_PATH}/.git/hooks exist!"
}

@test "git-client-hook: Hook will install only when NODE_ENV equals undefined or development" {
  git init

  unset NODE_ENV
  export NODE_ENV
  run git-client-hook.sh
  refute_output_contains "No need to install git-hook in NODE_ENV: "

  export NODE_ENV="development"
  run git-client-hook.sh
  refute_output_contains "No need to install git-hook in NODE_ENV: "

  export NODE_ENV="production"
  run git-client-hook.sh
  assert_output "No need to install git-hook in NODE_ENV: production."

  export NODE_ENV="release"
  run git-client-hook.sh
  assert_output "No need to install git-hook in NODE_ENV: release."
}

@test "git-client-hook: Hook will install/update only if there are some new hook files/contents." {
  git init

  HOOK_TEST_FILE_NAMES=($(ls $HOOK_TEST_REPO_PATH))
  export NODE_ENV="development"
  run git-client-hook.sh
  assert_line 0 "GIT LOCAL HOOK installing...! ⚙ "
  assert_output_contains "GIT LOCAL HOOK install done!  🍻"
  for hook_file in ${HOOK_TEST_FILE_NAMES[@]}
  do
    assert_output_contains "$hook_file installing..."
    assert_output_contains "$hook_file installed!"
  done

  echo "#add sth to git_hook" >> "$HOOK_TEST_REPO_PATH/${HOOK_TEST_FILE_NAMES[0]}"
  run git-client-hook.sh
  assert_output_contains "${HOOK_TEST_FILE_NAMES[0]} has changed: "
  assert_output_contains "${HOOK_TEST_FILE_NAMES[0]} updating..."
  assert_output_contains "${HOOK_TEST_FILE_NAMES[0]} updated!"

  run git-client-hook.sh
  assert_output_contains "No git hook need to update or install."
}

