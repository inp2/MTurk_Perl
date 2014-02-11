#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::RowData;

# perl processhits.pl -register
# register your Amazon Mturk Keys
#
# perl processhits.pl 
# loadHITs for bulk loading many hits.
# Data is read from a CSV input file
# which is merged with the question template to produce the xml for the question.
# Each row corresponds to a HIT.
# Progress messages will be printed to the console.
# Successful HITId and HITTypeId's will be printed to a CSV success file.
# Failed rows from the input file will be printed to a CSV failure file.
#
#perl processhits.pl -get
#Allows the results of the HITs to be received in the loadhits-results.csv
#
#perl processhits.pl -remove
#This removes all success hits 
#
#perl processhits.pl -wordcloud
#This is where the code for the word cloud should be placed

if($ARGV[0] eq "-register")
{
 system("perl -MNet::Amazon::MechanicalTurk::Configurer -e configure");
 die("You have been registered!");
}
elsif($ARGV[0] eq "-get")
{
	&getResults;
	die("Your files are located in loadhits-results.csv");
}
elsif($ARGV[0] eq "-remove")
{
	&removeHITS;
	die;
}
elsif($ARGV[0] eq "-wordcloud")
{
	&createWordCloud;
	die;
}
sub questionTemplate {
    my %params = %{$_[0]};
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>$params{question}</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

my $properties = {
    Title       => 'FAVORITE HASHTAG',
    Description => 'Let Us Know What Is Your Favorite HashTag.',
    Keywords    => 'Twitter, WordCloud, HCI',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.00
    },
    RequesterAnnotation         => 'Question',
    AssignmentDurationInSeconds => 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 3,
    LifetimeInSeconds           => 60 * 60
};

my $mturk = Net::Amazon::MechanicalTurk->new();

$mturk->loadHITs(
    properties => $properties,
    input      => "loadhits-input.csv",
    question   => \&questionTemplate,
    progress   => \*STDOUT,
    success    => "loadhits-success.csv",
    fail       => "loadhits-failure.csv"
);

sub getResults
{
	my $mturk = Net::Amazon::MechanicalTurk->new;

	$mturk->retrieveResults(
		input => "loadhits-success.csv",
		output => "loadhits-results.csv",
		progress => \*STDOUT
	);
}


sub removeHITS
{
	my $mturk = Net::Amazon::MechanicalTurk->new;
	my $data = Net::Amazon::MechanicalTurk::RowData->toRowData("loadhits-success.csv");

	my $autoApprove = 1;
	
	$data->each(sub {
		my ($data, $row) = @_;
		my $hitId = $row->{HITId};
	
		printf "Deleting hit $hitId\n";
		eval {
			$mturk->deleteHIT($hitId, $autoApprove);
		};
		if($@) {
			warn "Cloudn't delete hit $hitId - " . $mturk->response->errorCode . "\n";
		}
	}); 
}

sub createWordCloud
{
	print "This Is Where You Create The Word Cloud!\n";
}
