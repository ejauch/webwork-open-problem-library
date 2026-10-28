# Westminster College (Missouri) — WCMO

This directory contains WeBWorK problems contributed by Westminster College (Missouri).

Please contact

    Erich Jauch <erich.jauch@westminster-mo.edu>   GitHub: ejauch

with any questions, bug reports, or suggestions. Only GitHub user `ejauch` should modify problems in this directory.

## Organization

Problems are organized by course, then by topic within that course. File names give a short description of the problem, with a number for each version of the same idea (for example `HalfLife1.pg`, `HalfLife2.pg`).

| Course | Topic folder | Problems |
| --- | --- | --- |
| Quantitative_Reasoning | Counting | 7 |
| | Exponential_Change | 16 |
| | Logic | 28 |
| | Percentages | 11 |
| | Probability | 23 |
| | Statistics | 26 |
| | Unit_Conversion | 16 |

Every problem is randomized; none use a fixed seed.

## Tagging

Each problem starts with the same metadata block:

```
## DESCRIPTION
## Quantitative Reasoning: <short description>
## ENDDESCRIPTION

## DBsubject('...')
## DBchapter('...')
## DBsection('...')
## Date('M/D/YY')
## Author('Erich Jauch')
## Institution('Westminster College (Missouri)')
## KEYWORDS('...','...')
```

The DBsubject, DBchapter, and DBsection values are taken from the OPL taxonomy file `OpenProblemLibrary/Taxonomy2`. The OPL has no Quantitative Reasoning subject, so each problem is filed under the closest existing section (for example Arithmetic › Percents, Probability › Sample Space, or Set theory and logic › Propositional logic).

## Rounding macro: decimalPlaces.pl

Problems that ask students to round use a local macro, `decimalPlaces.pl`, instead of the default MathObject checker. The default checker accepts any answer within 0.1% of the correct value, so a student who types 3.1416 when asked to round to two decimal places is still marked correct. `DecimalPlacesCmp` instead requires

- exactly the requested number of decimal places, typed as a plain decimal (not an expression), and
- the value of the correctly rounded answer, with no tolerance.

Rounding is done with `Round` from `PGauxiliaryFunctions.pl`, so ties round half up (`sprintf` does not reliably do this).

### Where the macro lives

WeBWorK looks for macros in only three places: the folder of the problem being rendered, the course's `templates/macros` folder, and PG's own macro directories. For that reason a copy of `decimalPlaces.pl` sits in every topic folder whose problems use it:

- `Quantitative_Reasoning/Exponential_Change/`
- `Quantitative_Reasoning/Percentages/`
- `Quantitative_Reasoning/Probability/`
- `Quantitative_Reasoning/Statistics/`
- `Quantitative_Reasoning/Unit_Conversion/`

The five copies are identical; update all of them together. The plan is to propose the macro to `openwebwork/pg`; once it is part of PG, these copies will be removed and the problems will not need any other change.

**If you copy a single problem into your own course**, copy `decimalPlaces.pl` with it into the same folder, or put one copy in your course's `templates/macros` folder. Without it the problem will not load.

### Using it in a problem

Load the macro and pass the **unrounded** value:

```
loadMacros('PGstandard.pl', 'PGML.pl', 'decimalPlaces.pl', 'PGcourse.pl');

$x = 100.255;

BEGIN_PGML
Round [$x] to two decimal places: [_]{DecimalPlacesCmp($x, 2)}
END_PGML
```

- `DecimalPlacesCmp($value, $places)` works with plain numbers and MathObjects.
- Currency values (from `contextCurrency.pl`) are checked in the Currency context: students must include the dollar sign and give the answer to the cent.
- With `$places = 0`, the student must enter a whole number with no decimal point.
- Option `allowOmittedZeros => 1` accepts 2.5 for a correct answer of 2.50.
- Option `message => '...'` replaces the default wrong-format message.

Because the checker is strict, every problem that uses it says in its text how to round (for example "rounded to the nearest hundredth" or "to the nearest cent"). Please keep that wording if you modify a problem.

## Textbook

The Quantitative Reasoning problems follow the topics of *Using and Understanding Mathematics: A Quantitative Reasoning Approach* (7th ed.). The hints in `Statistics/Percentile1–3.pg` refer to the standard score table in Section 6C of that text.

--Erich Jauch, 2026-10-28
