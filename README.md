# Chadwick

Friends on one phone punch the wrong results off a week of matches, lock the card before kickoff, and collect points when someone types the final score. It is for roommates who want a points table without accounts, odds, or stakes.

## Architecture

The week is a fold on `Board`: Blank, Open, Perforated, Locked, Posted, or Void. Each coupon holds three outcome rows for one match. Punch toggles a hole. When every coupon has one open row, the board folds to Perforated. Lock before kickoff writes one lock and folds to Locked. Lock while any coupon still has two or more open rows is refused. Lock after kickoff voids that match. Post writes 3 points for a hit and 0 for a miss from the typed score, then folds to Posted. Standings are derived from posted coupons and are not stored.

That fold fits this product because the week is one card, not a list of independent bets. `CouponStore` is the only type that reads and writes the root (`chw.root.v1` and an atomic file in Application Support). Screens talk to `BoardDesk`.

## Why someone keeps it

Punch, then lock. You close two holes on every match until one result remains, and only then does Lock freeze the week. The opening Simulator week already has one hole punched, so the first tap is Punch, not Lock and not Post.

## Art

Soft 3D clay icons on a typographic stage. Matte, hand-pressed clay objects with rounded edges, gentle subsurface softness and a single soft key light. The subjects are a perforated paper coupon, a punch tool, a small padlock and a scoreboard digit, each a solid centered subject on real transparent alpha. The composition is calm and editorial, with generous air and big set type as the counterweight. There is no glass, no wireframe, no gambling chips, no coins and no money imagery.

- `chw_Onboarding1`: that prompt, a person or object that is this product in one glance.
- `chw_Onboarding2`: that prompt, the primary action of this product, mid-gesture.
- `chw_Onboarding3`: that prompt, a later moment when the product has accumulated meaning.
- `chw_EmptyHome`: that prompt, a solid closed bowl, crate or folded cloth waiting to be used.
- `chw_TwistHero`: that prompt, an emblem of punch-then-lock.
- `chw_EmptyBoard`: a blank perforated match coupon with three round punch holes still intact.
- `chw_LockedCoupon`: a punched coupon with two holes pressed out and one open, held by a small rounded clay padlock.

## How this differs

Same family as other week leagues, but the persisted verb is elimination punching and one lock. It is not purse-weighted picks, not an exact-score grid, and not a random result.

## Build

```
xcodegen generate
xcodebuild -scheme Chadwick -destination 'generic/platform=iOS' build
```

Tests live in `ChadwickTests`. Simulator launches with `-ReviewScreen today|log|goals` after the demo seed marks onboarding complete. The seed key is `chw.demo.v1` and it never runs on a device.
