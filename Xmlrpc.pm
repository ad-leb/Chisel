package Chisel::Xmlrpc;
use IO::Socket qw(AF_INET SOCK_STREAM);
use IO::Socket::SSL;
use Carp qw(carp croak);
use Chisel::Xml;





our $default = {
	port						=> 80,
	req							=>
		{
			content_type		=> 'text/xml',
			user_agent			=> 'perl-xmlrpc',
		},
};












sub new
{
	my ($self, $resource, %add) = @_;
	my $session;

	$session = clone($default);
	($session->{host}, $session->{port}) = split ':', $resource; 		$session->{port} = $default->{port} if !$session->{port};
	map { $session->{$_} = $add{$_} } keys %add;



	$session->{sock} = ($session->{port} == 443)
		?	IO::Socket::SSL->new(
				PeerHost				=> $session->{host},
				PeerPort				=> $session->{port},
			) 
		:	IO::Socket->new(
				Domain					=> AF_INET,
				Type					=> SOCK_STREAM,
				PeerHost				=> $session->{host},
				PeerPort				=> $session->{port},
			) 
	or croak("Xmlrpc [IO::Socket]: $!");

	my $oldfd = select $session->{sock};
	$| = 1;
	select $oldfd;



	return bless $session, $self;
}







sub post
{
	my ($this, $content) = @_;					
	my $fd = $this->{sock};
	my $str = '';



	$content = Chisel::Xml->pretty($content, $this->{format}->%*) if $content;
	$this->{req}{content_length} = ($content) ? length $content : 0;

	
	$str .= qq(POST $this->{source} HTTP/1.1\r\n);
	$str .= qq(Host: $this->{host}\r\n);
	$str .= join '', 
		map { 
			my ($key) = $_;

			if ( $key =~ /^content/ and !$content ) {
				'';
			} else {
				enc_http_header($key, $this->{req}{$key});
			}
		} keys $this->{req}->%*;
	$str .= qq(\r\n);
	$str .= $content if $content;

	print $fd $str;



	return $this->response;
}




sub response
{
	my ($this) = @_;
	my $fd = $this->{sock};
	my $res; $res->{content} = '';



	while (<$fd>)
	{
		/^\r?$/ && last;
		my ($key, $value) = dec_http_header($_);

		$res->{$key} = $value;
	}

	if ( $res->{content_length} ) {
		$res->{content} .= <$fd> while length $res->{content} < $res->{content_length};
	}

	$res->{xmlobj} = Chisel::Xml->read($res->{content}, $this->{format}->%*);



	return $res;
}

























sub enc_http_header
{
	my ($key, $value) = @_;

	$key =~ tr/_/-/;
	$key =~ s/\b(\w)/\U$1/g;

	return qq($key: $value\r\n);
}
sub dec_http_header
{
	my ($str) = @_;		$str =~ s/\r//;
	my ($key, $value);

	($key, $value) = ($1, $2)			if $str =~ /^(.*): (.*)$/;
	($key, $value) = ('status', $1)		if $str =~ /^HTTP.*(\d{3})/;

	return if !$key;

	$key =~ s/\b(\w)/\L$1/g;
	$key =~ tr/-/_/;

	return ($key, $value);
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
