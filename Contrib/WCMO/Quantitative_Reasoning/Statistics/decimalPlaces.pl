################################################################################
# decimalPlaces.pl
#
# Local macro (not part of the PG distribution). Keep a copy outside the
# webwork2/pg source trees so upgrades do not overwrite it.
################################################################################

=head1 NAME

decimalPlaces.pl - Answer checker that requires answers to be entered with an
exact number of decimal places.

=head1 DESCRIPTION

By default, a MathObject answer checker accepts any number within the context
tolerance (0.1% relative by default). So if the correct answer is 3.14, entries
such as 3.1416 or 3.141 are also marked correct, even when the problem asks for
the answer rounded to 2 decimal places.

This macro provides a checker that

=over

=item *

requires the student's answer, as typed, to have exactly the requested number
of decimal places (and to be a plain decimal number, not an expression such as
C<314/100>), and

=item *

requires the value to match the correctly rounded answer exactly, rather than
within the context tolerance.

=back

All rounding is done with C<Round> from F<PGauxiliaryFunctions.pl>, not with
C<sprintf>.

=head1 USAGE

    DOCUMENT();
    loadMacros('PGstandard.pl', 'PGML.pl', 'decimalPlaces.pl');

    $x = 100.255;

    BEGIN_PGML
    Round [`[$x]`] to two decimal places: [_]{DecimalPlacesCmp($x, 2)}{10}
    END_PGML

    ENDDOCUMENT();

Pass the B<unrounded> value. The macro rounds it with C<Round>.

The value may be a plain Perl number or a MathObject; the macro converts
MathObjects to plain numbers before rounding. This matters: calling
C<Round($mathObject, $n)> directly gives the wrong result on exact ties such as
562.5, because C<Round> numifies its argument through the object's string and
loses the adjustment it relies on. If you call C<Round> yourself elsewhere in a
problem, pass C<< $mathObject->value >> rather than the object.

In non-PGML problems:

    ANS(DecimalPlacesCmp($x, 2));

=head2 Currency answers

If the value is a Currency object (or you pass C<< currency => 1 >>), the
checker works in the Currency context: the student must include the currency
symbol, commas are optional, and the correct answer is displayed as currency.

    Context('Currency');
    $cost = Currency(45.675);

    BEGIN_PGML
    Cost, to the nearest cent: [_]{DecimalPlacesCmp($cost, 2)}
    END_PGML

For the usual 2 decimal places this hands the format check to
F<contextCurrency.pl> itself, by setting its C<forceDecimals> flag, so the
student gets that context's own error messages. Its tolerance is already .005
absolute, so answers must be correct to the penny. What the macro adds is
rounding the correct answer with C<Round>: the Currency C<< ->round >> method
uses C<sprintf>, so C<< Currency(0.125)->round >> gives $0.12, while this macro
gives $0.13.

Options such as C<< promoteReals => 1 >> (accept 45.68 without the symbol) and
C<< forceCommas => 1 >> are passed through to C<cmp>.

=head1 FUNCTIONS

=head2 DecimalPlacesCmp($value, $places, %options)

Returns an answer checker for C<$value> rounded to C<$places> decimal places.

Options:

=over

=item C<allowOmittedZeros> (default 0)

If 1, students may leave off trailing zeros: with a correct answer of 2.50,
the entry 2.5 is accepted. An entry such as 2.49 or 2.5 for a correct answer of
2.49 is still wrong, since the value must match exactly. With the default of 0,
exactly C<$places> digits after the decimal point are required.

=item C<message>

The message shown when the answer has the wrong format. Defaults to
"Your answer must be rounded to exactly N decimal places."

=item C<hints>

A list of common wrong answers, each with a message to show when a student
enters it. Pass the B<unrounded> wrong value, just like the correct one:

    DecimalPlacesCmp($std, 2, hints => [
        [ $popStd, "It looks like you divided by n. ..." ],
        [ $var,    "It looks like you found the variance. ..." ],
    ])

The answer is still marked wrong; the message only explains why. Each wrong
value is rounded with C<Round> to C<$places> places and matched within
C<hintTolerance> units of the last place, so students who rounded a little
differently along the way still get the hint. A hint is skipped automatically
if its rounded value is too close to the correct answer to tell apart. Hints
are checked in order and only the first match is shown, and only after the
answer passes the format check.

=item C<hintTolerance> (default 1)

How far, in units of the last decimal place, a student's answer may be from a
hint value and still trigger it. With 2 places the default of 1 means
within 0.01. Use 0 to require an exact match.

=item C<nearMiss> (default 0, off)

If set, a wrong answer that matches none of the C<hints> but is within this
relative distance of the correct answer gets the C<nearMissMessage>. For
example, C<< nearMiss => 0.01 >> catches answers within 1% of the correct one,
which usually means the student rounded too early or used a slightly different
conversion factor. The answer is still marked wrong.

=item C<nearMissMessage>

The message for C<nearMiss>. Defaults to "Your answer is close, but not exact.
Keep all of the digits until the final step, then round."

=item Any other option

Passed through to the MathObject C<cmp> method (for example C<showTypeWarnings>).

=back

The displayed correct answer is padded to C<$places> places (2.50, not 2.5).

=head2 CurrencyPlacesCmp($value, $places, %options)

Same thing for currency values, called directly. C<$places> defaults to 2.
C<DecimalPlacesCmp> calls this automatically for Currency values, so you only
need it when C<$value> is a plain number that should be checked as currency.
The C<hints>, C<hintTolerance>, C<nearMiss> and C<nearMissMessage> options
work the same way as for C<DecimalPlacesCmp>.

=head2 DecimalPlacesString($value, $places)

Returns C<$value> rounded to C<$places> places as a string padded with trailing
zeros, e.g. C<DecimalPlacesString(2.5, 2)> gives C<"2.50">. Useful for showing
a rounded value in problem text or a solution.

=head1 NOTES

=over

=item *

With C<$places> = 0, the student must enter an integer with no decimal point.

=item *

Leading zeros are optional: C<.25> and C<0.25> are both accepted.

=item *

Scientific notation (C<3.14E0>) is rejected as the wrong format.

=back

=cut

loadMacros('MathObjects.pl', 'PGauxiliaryFunctions.pl');

sub _decimalPlaces_init { }

# Round() works via sprintf("%E", $x). Value.pm overloads stringification but
# not numeric conversion, so a MathObject passed to Round is numified through
# its (finite precision) string, which destroys Round's internal adjustment and
# leaves exact ties to the C library's round-half-to-even. Always hand Round a
# plain Perl number.
sub _decimalPlaces_number {
	my $value = shift;
	if (ref($value) && Value::isValue($value)) {
		$value = $value->eval if $value->isFormula;
		$value = $value->value;
	}
	return $value + 0;
}

# Given the rounded correct value, the student's value and the hints list
# ([value, message] pairs, unrounded), return the message of the first hint the
# student's value matches, or undef. Kept separate from the checker so it can be
# tested on its own.
sub _decimalPlaces_hint {
	my ($correct, $student, $places, $hints, $tolerance) = @_;
	return undef unless $hints && @$hints;
	my $unit = 10**(-$places);
	my $tol  = $tolerance * $unit + 1E-9;
	foreach my $hint (@$hints) {
		my ($value, $msg) = @$hint;
		my $r = Round(_decimalPlaces_number($value), $places);
		next if abs($r - $correct) <= $tol;    # cannot be told apart from the right answer
		return $msg if abs($student - $r) <= $tol;
	}
	return undef;
}

# Pull the feedback options out of %$options (removing them so they are not
# passed on to cmp) and return them as a hash reference.
sub _decimalPlaces_feedbackOptions {
	my $options = shift;
	return {
		hints           => delete $options->{hints},
		hintTolerance   => delete $options->{hintTolerance} // 1,
		nearMiss        => delete $options->{nearMiss} // 0,
		nearMissMessage => delete $options->{nearMissMessage}
			// 'Your answer is close, but not exact. Keep all of the digits until the final step, then round.',
	};
}

# The message for a wrong answer: the first matching hint, otherwise the near
# miss message if the answer is close enough, otherwise undef.
sub _decimalPlaces_feedback {
	my ($correct, $student, $places, $fb) = @_;
	my $hint = _decimalPlaces_hint($correct, $student, $places, $fb->{hints}, $fb->{hintTolerance});
	return $hint if defined $hint;
	return $fb->{nearMissMessage}
		if $fb->{nearMiss} && abs($student - $correct) <= $fb->{nearMiss} * abs($correct);
	return undef;
}

sub DecimalPlacesString {
	my ($value, $places) = @_;
	$value = _decimalPlaces_number($value);
	my $rounded = Round($value, $places);
	$rounded = 0 if $rounded == 0;    # avoid "-0"
	return "$rounded" if $places == 0;

	my $s = "$rounded";
	# Perl uses exponential notation for very small/large numbers. Since the
	# value is already rounded by Round, sprintf here only pads; it does no
	# rounding of its own.
	return sprintf("%.${places}f", $rounded) if $s =~ /e/i;

	$s .= '.' unless $s =~ /\./;
	my ($frac) = $s =~ /\.(\d*)$/;
	$s .= '0' x ($places - length($frac));
	return $s;
}

sub DecimalPlacesCmp {
	my ($value, $places, %options) = @_;

	my $isCurrency =
		exists $options{currency}
		? delete $options{currency}
		: (ref($value) && Value::isValue($value) && $value->{isCurrency} ? 1 : 0);
	return CurrencyPlacesCmp($value, $places, %options) if $isCurrency;

	$value = _decimalPlaces_number($value);
	my $allowOmittedZeros = delete $options{allowOmittedZeros} // 0;
	my $feedback          = _decimalPlaces_feedbackOptions(\%options);
	my $message           = delete $options{message}
		// "Your answer must be rounded to exactly $places decimal place"
		. ($places == 1 ? '' : 's') . '.';

	my $rounded = Round($value, $places);
	$rounded = 0 if $rounded == 0;
	my $answer = Real($rounded);

	my $pattern =
		$places == 0       ? qr/^[+-]?\d+$/
		: $allowOmittedZeros ? qr/^[+-]?(?:\d+\.?\d{0,$places}|\.\d{1,$places})$/
		:                      qr/^[+-]?\d*\.\d{$places}$/;

	return $answer->cmp(
		correct_ans => DecimalPlacesString($value, $places),
		%options,
		checker => sub {
			my ($correct, $student, $ansHash) = @_;
			my $raw = $ansHash->{original_student_ans} // '';
			$raw =~ s/\s+//g;
			Value->Error($message) unless $raw =~ $pattern;
			my ($c, $s) = ($correct->value, $student->value);
			return 1 if abs($c - $s) <= 1E-10 * (abs($c) > 1 ? abs($c) : 1);
			my $hint = _decimalPlaces_feedback($c, $s, $places, $feedback);
			$ansHash->{ans_message} = $hint if defined $hint;
			return 0;
		}
	);
}

sub CurrencyPlacesCmp {
	my ($value, $places, %options) = @_;
	$places = 2 unless defined $places;
	delete $options{currency};
	my $feedback = _decimalPlaces_feedbackOptions(\%options);

	my $context = (ref($value) && Value::isValue($value)) ? $value->context : $main::context{Currency};
	Value::Error("CurrencyPlacesCmp requires the Currency context (load contextCurrency.pl)")
		unless $context && $context->{currency};

	# Round with Round, not with the Currency round() method, which uses sprintf.
	my $rounded = Round(_decimalPlaces_number($value), $places);
	$rounded = 0 if $rounded == 0;
	my $answer = Value->Package('Currency')->new($context, $rounded);

	# Two decimals is what contextCurrency.pl checks natively, and its .005
	# absolute tolerance already requires the answer to the penny.
	return _decimalPlaces_currencyFeedback($answer->cmp(forceDecimals => 1, %options), $rounded, $places, $feedback)
		if $places == 2;

	my $message = delete $options{message}
		// "Your answer must be rounded to exactly $places decimal place"
		. ($places == 1 ? '' : 's') . '.';
	my $decimal = quotemeta($context->{currency}{decimal} // '.');
	my $pattern = $places == 0 ? qr/^[+-]?\d+$/ : qr/^[+-]?\d*$decimal\d{$places}$/;

	my $cmp = $answer->cmp(
		forceDecimals   => 0,
		noExtraDecimals => 0,
		($places == 0 ? (trimTrailingZeros => 1) : ()),
		%options,
		checker => sub {
			my ($correct, $student, $ansHash) = @_;
			my $raw = $ansHash->{original_student_ans} // '';
			$raw =~ s/[^0-9+\-$decimal]//g;    # drop symbol, commas, spaces
			Value->Error($message) unless $raw =~ $pattern;
			my ($c, $s) = ($correct->value, $student->value);
			return abs($c - $s) <= 1E-10 * (abs($c) > 1 ? abs($c) : 1);
		}
	);
	return _decimalPlaces_currencyFeedback($cmp, $rounded, $places, $feedback);
}

# Currency answers are checked by contextCurrency.pl, so hints are added with a
# post filter. It only acts on a wrong answer that has no other message.
sub _decimalPlaces_currencyFeedback {
	my ($cmp, $correct, $places, $fb) = @_;
	return $cmp unless ($fb->{hints} && @{ $fb->{hints} }) || $fb->{nearMiss};
	return $cmp->withPostFilter(sub {
		my $ansHash = shift;
		return $ansHash if $ansHash->{score} >= 1 || ($ansHash->{ans_message} // '') ne '';
		my $student = $ansHash->{student_value};
		return $ansHash unless defined $student && Value::isValue($student);
		my $s = eval { $student->value };
		return $ansHash unless defined $s && !ref($s) && $s =~ /^[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$/;
		my $hint = _decimalPlaces_feedback($correct, $s, $places, $fb);
		$ansHash->{ans_message} = $hint if defined $hint;
		return $ansHash;
	});
}

1;
