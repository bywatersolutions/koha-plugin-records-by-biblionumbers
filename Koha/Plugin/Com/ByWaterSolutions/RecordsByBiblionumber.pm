package Koha::Plugin::Com::ByWaterSolutions::RecordsByBiblionumber;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Auth;
use Koha::Database;

## Here we set our plugin version
our $VERSION = "{VERSION}";
our $MINIMUM_VERSION = "{MINIMUM_VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Records by Biblionumbers',
    author          => 'Kyle M Hall',
    description     => 'Enter a list of biblionumbers ( or barcodes ), get a list of titles!',
    date_authored   => '2014-08-20',
    date_updated    => "1900-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('output') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'report-step1.tt' } );

    print $cgi->header();
    print $template->output();
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $biblionumbers = $cgi->param('biblionumbers');
    my $input         = $cgi->param('input') || "biblionumber";
    my $output        = $cgi->param('output');

    my @numbers = split( /[\n,\r\n,\t,\,]/, $biblionumbers );
    map { $_ =~ s/^\s+|\s+$//g  } @numbers;

    my $schema = Koha::Database->new()->schema();

    my @items = $schema->resultset("Item")->search(
        { $input   => { -in  => \@numbers } },
        { order_by => { -asc => 'biblionumber' } }
    );

    my $filename;
    if ( $output eq "csv" ) {
        print $cgi->header( -attachment => 'records.csv' );
        $filename = 'report-step2-csv.tt';
    }
    else {
        print $cgi->header();
        $filename = 'report-step2-html.tt';
    }

    my $template = $self->get_template( { file => $filename } );

    $template->param( items => \@items );

    print $template->output();
}

1;
