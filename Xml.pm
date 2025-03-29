package TwentyFive::Xml;





our %const = (
	tab							=> '  ',
	break						=> "\n",
);









sub AUTOLOAD
{
	my ($self, $obj, $name) = @_;			$name = 'object' if !$name;
	my ($method) = ($AUTOLOAD =~ /::(.*)/);
	my $str = '<?xml version="1.0" encoding="UTF-8"?>';


	if ($method eq 'pretty') {
		$str .= "\n" . enc_pretty($obj, $name, 0);
	} else {
		$str .= enc($obj, $name);
	}


	return $str;
}











sub enc
{
	my ($obj, $name) = @_;
	my $str = '';


	$name = ch_enc($name);

	$str .= "<$name>";
	if ( ref $obj eq 'ARRAY' ) {
		map { $str .= enc($obj->[$_], "item_$_") } 0..$#$obj;
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
	my ($preffix, $terminator) = ($const{tab} x $deep, $const{break});
	my $str = '';


	$name = ch_enc($name);

	$str .= $preffix . "<$name>";
	if ( ref $obj eq 'ARRAY' ) {
		$str .= $terminator;
		map { $str .= enc_pretty($obj->[$_], "item_$_", $deep + 1) } 0..$#$obj;
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
    my ($self, $str, $arr_list) = @_;
    my $obj;


    $str =~ s/<\?xml.*\?>//;
	$str = ch_dec($str);
	($obj, $str) = dec($str, $arr_list);


    return $obj;
}


sub dec
{
	my ($str, $list, $arr) = @_;
	my $obj;


	while ( $str )
	{
		my ($tag, $tmp);

		($tag, $str) = pull_tag($str);
		if ( $tag->{type} eq 'open' ) {
			($tmp, $str) = dec($str, $list, grep /^$tag->{word}$/, $list->@*);
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



























1;
