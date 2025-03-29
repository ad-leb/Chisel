package Chisel::Xml;





our %default = (
	tab							=> '  ',
	break						=> "\n",
	name						=> 'object',
);
our $format;









sub AUTOLOAD
{
	my ($self, $obj, %add) = @_;
	my ($method) = ($AUTOLOAD =~ /.*::(.*)$/);
	my $str = '<?xml version="1.0" encoding="UTF-8"?>';


	$format = clone(\%default);
	map { $format->{$_} = $add{$_} } keys %add;

	if ($method eq 'pretty') {
		$str .= "\n" . enc_pretty($obj, $format->{name}, 0);
	} else {
		$str .= enc($obj, $format->{name});
	}

	$format = undef;


	return $str;
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











sub read
{
    my ($self, $str, %add) = @_;
    my $obj;


	$format->{array} = $arr_list;
	map { $format->{$_} = $add{$_} } keys %add;

    $str =~ s/<\?xml.*\?>//;
	$str = ch_dec($str);
	($obj, $str) = dec($str);

	$format = undef;


    return $obj;
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
				&& (push $obj->@*, $tmp)
				|| ($obj->{$tag->{word}} = $tmp)
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
		&& ($tag->{type} = 'open')
		&& ($str =~ s/^<(.*?)>/$1\0/s)
		|| ($str =~ s/^(.*?)\s*</$1\0</s)
	;
	$str =~ /^\//s
		&& ($tag->{type} = 'close')
		&& ($str =~ s/^\///s)
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
