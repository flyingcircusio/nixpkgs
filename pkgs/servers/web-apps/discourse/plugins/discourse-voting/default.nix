{
  lib,
  mkDiscoursePlugin,
  fetchFromGitHub,
}:

mkDiscoursePlugin {
  name = "discourse-voting";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-topic-voting";
    rev = "0390f3611ea3b635877b349e9fb38aac01e19837";
    sha256 = "sha256-4w+E24hWWTB0boCMjNdz49Aw2ioekWNVvc/ar6laHPQ=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-voting";
    maintainers = with maintainers; [ dpausp ];
    license = licenses.gpl2Only;
    description = "Adds the ability for voting on a topic within a specified category in Discourse";
  };
}
