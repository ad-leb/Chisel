package Xml;





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


	$name = char_entity($name);

	$str .= "<$name>";
	if ( ref $obj eq 'ARRAY' ) {
		map { $str .= enc($obj->[$_], "item_$_") } 0..$#$obj;
	} elsif ( ref $obj eq 'HASH' ) {
		map { $str .= enc($obj->{$_}, $_) } keys $obj->%*;
	} else {
		$str .= char_entity($obj);
	}
	$str .= "</$name>";


	return $str;
}



sub enc_pretty
{
	my ($obj, $name, $deep) = @_;
	my ($preffix, $terminator) = ($const{tab} x $deep, $const{break});
	my $str = '';


	$name = char_entity($name);

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
		$str .= char_entity($obj);
	}
	$str .= "</$name>" . $terminator;


	return $str;
}



sub char_entity
{
	$_ = shift;

	s/\&/\&amp;/g;
	s/\"/\&quot;/g;
	s/\'/\&apos;/g;
	s/\</\&lt;/g;
	s/\>/\&rt;/g;

	return $_;
}



























1;
