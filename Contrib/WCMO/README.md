# Westminster College (Missouri) — WCMO

This directory contains WeBWorK problems contributed by Westminster College (Missouri).

Please contact

    Erich Jauch <erich.jauch@westminster-mo.edu>   GitHub: ejauch

with any questions, bug reports, or suggestions. Only GitHub user `ejauch` should modify problems in this directory.

## Organization

Problems are organized by course, then by topic within that course. File names give a short description of the problem, with a number for each version of the same idea (for example `HalfLife1.pg`, `HalfLife2.pg`).

| Course | Topic folder | Problems |
| --- | --- | --- |
| Quantitative_Reasoning | Counting | 9 |
| | Exponential_Change | 18 |
| | Logic | 30 |
| | Numbers | 2 |
| | Percentages | 14 |
| | Probability | 26 |
| | Statistics | 27 |
| | Unit_Conversion | 18 |
| | **Total** | **144** |

Every problem is randomized; none use a fixed seed.

Some numbered sets fix one variation per file so an instructor can choose exactly what to assign. For example, `Logic/ConditionalVennDiagram1–4.pg` each test one argument form (affirming the hypothesis, denying the hypothesis, affirming the conclusion, denying the conclusion), while `Logic/ConditionalVennDiagram.pg` picks one of the four at random.

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
- Option `hints => [ [$wrongValue, 'message'], ... ]` shows a message when a student enters a common wrong answer. Pass the unrounded wrong value; it is rounded the same way as the correct answer and matched within `hintTolerance` units of the last decimal place (default 1). A hint that would round to the correct answer is skipped automatically.
- Option `nearMiss => 0.01` shows `nearMissMessage` for a wrong answer within 1% of the correct one (usually a student who rounded too early or used a slightly different conversion factor).

For example, from `Unit_Conversion/UnitConversion1.pg`:

```
[____]{DecimalPlacesCmp($speed, 2, hints => $speedHints, nearMiss => 0.01, nearMissMessage => $closeMsg)}
```

Because the checker is strict, every problem that uses it says in its text how to round (for example "rounded to the nearest hundredth" or "to the nearest cent"). Please keep that wording if you modify a problem.

## Hints for common wrong answers

Many problems give students a short message when they enter a common wrong answer (for example, a permutation where a combination was needed, or a speed left in meters per second). The answer is still marked wrong; the message only explains what went wrong. Problems that round to decimal places use the `hints` option of `DecimalPlacesCmp` described above. Other problems use PG's standard `answerHints.pl` macro, so nothing extra needs to be copied for those:

```
$ansCmp = Real($ans)->cmp->withPostFilter(AnswerHints(
    Real(C($team, 4)) => "That counts groups of 4 players where order does not matter. ...",
));
```

## Scientific notation answers

Problems whose answer is very large or very small (`Counting/Counting1–2.pg`, `Probability/Lotto1–3.pg`, `Numbers/ScientificNotation1–2.pg`) use PG's `contextScientificNotation.pl`. Students enter the answer as a number between 1 and 10 times a power of 10 (for example `3.233x10^8`), with a fixed number of digits after the decimal point, and the problem text states how many significant digits to keep. These answers are checked to that many significant digits rather than with `decimalPlaces.pl`. In `Lotto1–3.pg` the count ("how many ...") is checked as an ordinary number before the context changes to scientific notation.

## Writing problems

Files ending in `Writing.pg` add a short written component to an existing problem. They are practice for explaining and justifying an answer in a sentence or two, and are graded partly by hand.

| File | Based on | Written part |
| --- | --- | --- |
| `Exponential_Change/DoublingTimeWriting.pg` | `DoublingTime2.pg` | Decide whether the population passes a threshold after a given time and justify the answer. |
| `Percentages/PercentOfPercentWriting.pg` | `PercentOfPercent.pg` | Explain why a classmate's answer, which subtracts percentage points, is wrong. |

Each one keeps the original calculation, adds a Yes/No choice and a supporting number (all graded automatically, with the same hints as the other problems), and ends with an essay box. The essay uses PG's standard `PGessaymacros.pl` (`essay_box` and `essay_cmp`), so nothing extra needs to be copied, but the instructor must grade the written answer by hand; a 0–4 scoring guide works well, and each problem's solution includes a model answer. Because of the manual grading, assign the original versions instead when a fully automatic set is wanted.

## Textbook

The Quantitative Reasoning problems follow the topics of *Using and Understanding Mathematics: A Quantitative Reasoning Approach* (7th ed.). The hints in `Statistics/Percentile1–4.pg` refer to the standard score table in Section 6C of that text.

--Erich Jauch, 2026-11-18
