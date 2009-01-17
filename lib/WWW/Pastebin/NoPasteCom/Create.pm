package WWW::Pastebin::NoPasteCom::Create;

use warnings;
use strict;

our $VERSION = '0.001';

use Carp;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw(
    ua
    paste_uri
    error
);

use overload q|""| => sub { shift->paste_uri; };

my %Valid_Syntax_Highlights = (
    c       => 'C/C++',
    html    => 'HTML',
    pascal  => 'Pascal / Delphi',
    plain   => 'Plain',
    rhtml   => 'RHTML',
    ruby    => 'Ruby',
    xml     => 'XML',
);

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;
    $args{ua} ||= LWP::UserAgent->new(
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    my $self = bless {}, $class;
    $self->ua( $args{ua} );

    return $self;
}

sub paste {
    my ( $self, $text ) = splice @_, 0, 2;

    $self->$_(undef) for qw(paste_uri error);
    
    defined $text or carp "Undefined paste content" and return;
    
    croak "Must have even number of optional arguments to paste()"
        if @_ & 1;

    my %args = @_;
    %args = (
        content     => $text,
        nick        => '',
        desc        => '',
        lang        => 'plain',

        %args,
    );

    $args{lang} = lc $args{lang};
    croak "Invalid value for 'lang' argument to paste()"
        unless exists $Valid_Syntax_Highlights{ $args{lang} };
        
    $args{file}
        and not -e $args{content}
        and return $self->_set_error(
            "File $args{source} does not seem to exist"
        );

    @args{qw/language description/} = delete @args{qw/lang desc/};

    my $ua = $self->ua;
    $ua->requests_redirectable( [ ] );
    my @post_request = $self->_make_request_args( \%args );
    my $response = $self->ua->request( POST @post_request );
    if ( $response->code == 302 ) {
        my $created_paste_uri = $response->header('Location');
        $created_paste_uri =~ s|redirect/||;
        return $self->paste_uri( URI->new( $created_paste_uri ) );
    }
    elsif ( not $response->is_success ) {
        return $self->_set_error( $response, 'net' );    
    }
    else {
        return $self->_set_error(
            q|Request was successfull but I don't see a link to the paste| .
                $response->code . $response->content
        );
    }
}

sub _make_request_args {
    my ( $self, $args ) = @_;
    my %content = (
        exists $args->{file}
        ? ( file => [ $args->{content} ], content => '' )
        : ( content => $args->{content}, file => '' )
    );
    delete @$args{qw(file content)};
    %content = ( %$args, %content );

    return (
        'http://nopaste.com/add',
        Content_Type => 'form-data',
        Content => [ %content ],
    );
}

sub _set_error {
    my ( $self, $error, $type ) = @_;
    if ( defined $type and $type eq 'net' ) {
        $self->error( 'Network error: ' . $error->status_line );
    }
    else {
        $self->error( $error );
    }
    return;
}


1;
__END__


=head1 NAME

WWW::Pastebin::NoPasteCom::Create - create new pastes on http://nopaste.com/ pastebin site

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Pastebin::NoPasteCom::Create;

    my $paster = WWW::Pastebin::NoPasteCom::Create->new;

    $paster->paste('large text to paste')
        or die $paster->error;

    print "Your paste is located on $paster\n";

=head1 DESCRIPTION

The module provides interface to paste large texts or files to
L<http://nopaste.com/>

=head1 CONSTRUCTOR

=head2 new

    my $paster = WWW::Pastebin::NoPasteCom::Create->new;

    my $paster = WWW::Pastebin::NoPasteCom::Create->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::NoPasteCom::Create->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::Pastebin::NoPasteCom::Create
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for pasting. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for pasting, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::NoPasteCom::Create>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 paste

    my $paste_uri = $paster->paste('lots and lots of text')
        or die $paster->error;

    $paster->paste(
        'paste.txt',
        file    => 1,
        nick    => 'Zoffix',
        desc    => 'paste from file',
        lang    => 'perl',
    ) or die $paster->error;

Instructs the object to create a new paste. If an error occured during
pasting will return either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method.
On success returns a L<URI> object pointing to a newly created paste.
The first argument is mandatory and must be either a scalar containing
the text to paste or a filename. The rest of the arguments are optional
and are passed in a key/value fashion. Possible arguments are as follows:

=head3 file

    $paster->paste( 'paste.txt', file => 1 );

B<Optional>.
When set to a true value the object will treat the first argument as a
filename of the file containing the text to paste. When set to a false
value the object will treat the first argument as a scalar containing
the text to be pasted. B<Defaults to:> C<0>

=head3 nick

    $paster->paste( 'some text', nick => 'Zoffix' );

B<Optional>. Takes a scalar as a value which specifies the nick of the
person creating the paste. B<Defaults to:> empty string (no nick)

=head3 desc

    $paster->paste( 'some text', desc => 'some l33t codez' );

B<Optional>. Takes a scalar as a value which specifies the description of
the paste. B<Defaults to:> empty string (no description)

=head3 lang

    $paster->paste( 'some text', lang => 'perl' );

B<Optional>. Takes a scalar as a value which must be one of predefined
language codes and specifies (computer) language of the paste, in other
words which syntax highlighting to use. B<Defaults to:> C<plain>. Valid
language codes are as follows (case insensitive):

    c
    html
    pascal
    plain
    rhtml
    ruby
    xml

=head2 error

    my $paste_uri = $paster->paste('lots and lots of text')
        or die $paster->error;

If an error occured during the call to C<paste()>
it will return either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method. Takes
no arguments, returns a human parsable error message explaining why
we failed.

=head2 paste_uri

    my $last_paste_uri = $paster->paste_uri;

    print "Paste can be found on $paster\n";

Must be called after a successfull call to C<paste()>. Takes no arguments,
returns a L<URI> object pointing to a paste created by the last call
to C<paste()>, i.e. the return value of the last C<paste()> call. This
method is overloaded as C<q|""> thus you can simply interpolate your
object in a string to obtain the paste URI.

=head2 ua

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used L<LWP::UserAgent> object used for pating. Takes one
optional argument which must be an L<LWP::UserAgent>
object, and the object you specify will be used in any subsequent calls
to C<paste()>.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-nopastecom-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-NoPasteCom-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::NoPasteCom::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-NoPasteCom-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-NoPasteCom-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-NoPasteCom-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-NoPasteCom-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
