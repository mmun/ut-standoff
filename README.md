# Standoff for Unreal Tournament

Standoff is a custom Unreal Tournament 99 game type that repeatedly pits two teams against eachother in a CTF flag standoff situation.

## Development

- Clone the repository into your root Unreal Tournament directory
  ```
  cd C:\Path\To\UnrealTournament
  git https://github.com/mmun/ut-standoff.git Standoff
  ```
- Copy `Standoff.int` into your root Unreal Tournament directory
- Add `Standoff` to your `EditPackages` in `UnrealTournament.ini`
- Build the package with `ucc make`
