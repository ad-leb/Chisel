package Chisel::Xml;





our %default = (
	tab							=> '  ',
	break						=> "\n",
	name						=> 'object',
);
our $format;
our $pretty;










sub import
{
	no strict 'refs';
	my ($package, $filename, $line) = caller;

	$pretty++ if grep /^pretty$/, @_;

	*{$package . "::$_"} = \&$_ foreach qw(to_xml from_xml);
}














sub to_xml
{
	my ($obj, %add) = @_;
	my $str = '<?xml version="1.0" encoding="UTF-8"?>';


	$format = clone(\%default);
	map { $format->{$_} = $add{$_} } keys %add;

	if ($pretty) {
		$str .= "\n" . enc_pretty($obj, $format->{name}, 0);
	} else {
		$str .= enc($obj, $format->{name});
	}

	$format = undef;


	return $str;
}


sub from_xml
{
    my ($str, %add) = @_;
    my $obj;


	$format->{array} = $arr_list;
	map { $format->{$_} = $add{$_} } keys %add;

    $str =~ s/<\?xml.*\?>//;
	$str = ch_dec($str);
	($obj, $str) = dec($str);

	$format = undef;


    return $obj;
}















sub enc
{
	my ($obj, $name) = @_;
	my $str = '';


	$name = ch_enc($name);

	$str .= "<$name>";
	if ( ref $obj eq 'ARRAY' ) {
		my $key = $format->{array}{$name};		$key = 'item' if !$key;
		map { $str .= enc($obj->[$_], "$key") } 0..$#$obj;
	} elsif ( ref $obj eq 'HASH' ) {
		map { $str .= enc($obj->{$_}, $_) } keys $obj->%*;
	} else {
		$str .= ch_enc($obj);
	}
	$str .= "</$name>";


	return $str;
}



sub enc_pretty
{
	my ($obj, $name, $deep) = @_;
	my ($preffix, $terminator) = ($format->{tab} x $deep, $format->{break});
	my $str = '';


	$name = ch_enc($name);

	$str .= $preffix . "<$name>";
	if ( ref $obj eq 'ARRAY' ) {
		$str .= $terminator;
		my $key = $format->{array}{$name};		$key = 'item' if !$key;
		map { $str .= enc_pretty($obj->[$_], "$key", $deep + 1) } 0..$#$obj;
		$str .= $preffix;
	} elsif ( ref $obj eq 'HASH' ) {
		$str .= $terminator;
		map { $str .= enc_pretty($obj->{$_}, $_, $deep + 1) } keys $obj->%*;
		$str .= $preffix;
	} else {
		$str .= ch_enc($obj);
	}
	$str .= "</$name>" . $terminator;


	return $str;
}



sub dec
{
	my ($str, $arr) = @_;
	my $obj;


	while ( $str )
	{
		my ($tag, $tmp);

		($tag, $str) = pull_tag($str);
		if ( $tag->{type} eq 'open' ) {
			($tmp, $str) = dec($str, grep /^$tag->{word}$/, keys $format->{array}->%*);
			$arr
				and push $obj->@*, $tmp
				or $obj->{$tag->{word}} = $tmp
			;
		} elsif ( $tag->{type} eq 'close' ) {
			last;
		} else {
			$obj = $tag->{word};
		}
	}


	return $obj, $str;
}
















sub pull_tag
{
	my ($str) = @_;
	my $tag;	$tag->{type} = 'str';


	$str =~ s/(^\s*|\s*$)//sg;
	$str =~ /^</s
		and $tag->{type} = 'open'
		and $str =~ s/^<(.*?)>/$1\0/s
		or $str =~ s/^(.*?)\s*</$1\0</s
	;
	$str =~ /^\//s
		and $tag->{type} = 'close'
		and $str =~ s/^\///s
	;
	($tag->{word}) = $str =~ /^(.*?)\0/s;
	$str =~ s/^(.*?)\0//sg;


	return $tag, $str;
}



sub ch_enc
{
	$_ = shift;

	s/\&/\&amp;/g;
	s/\"/\&quot;/g;
	s/\'/\&apos;/g;
	s/\</\&lt;/g;
	s/\>/\&rt;/g;

	return $_;
}
sub ch_dec
{
	$_ = shift;

	s/&quot;/\"/g;
	s/&apos;/\'/g;
	s/&lt;/\</g;
	s/&rt;/\>/g;
	s/&amp;/\&/g;

	return $_;
}












sub clone
{
	my ($obj) = @_;
	my $tadpole;


	if ( ref $obj eq 'ARRAY' ) {
		push $tadpole->@*, map { clone($_) } $obj->@*;
	} elsif ( ref $obj eq 'HASH' ) {
		map { $tadpole->{$_} = clone($obj->{$_}) } keys $obj->%*;
	} else {
		$tadpole = $obj;
	}


	return $tadpole;
}






















1;
