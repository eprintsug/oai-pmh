=pod

=head1 NAME

B<EPrints::OpenArchives> - Patched methods for improved open archives support in EPrints.

=head1 DESCRIPTION

This file patches EPrints::OpenArchives.

These methods were copied from 
 https://github.com/eprints/eprints/blob/3.3/perl_lib/EPrints/OpenArchives.pm
 (last updated 7th June 2011)

Previously only the archive and deletion datasets were reported in 
the OAI-PMH interface. This patch (combined with a patch to
cgi/oai2) will search for anything with a datestamp, and report
anything not in the archive dataset as deleted via OAI-PMH.

=cut

{
use strict;

package EPrints::OpenArchives;

no warnings;

sub make_header
{
	my ( $session, $eprint, $oai2 ) = @_;

	my $header = $session->make_element( "header" );
	my $oai_id = archive_id( $session );
	
	$header->appendChild( $session->render_data_element(
		6,
		"identifier",
		EPrints::OpenArchives::to_oai_identifier(
			$oai_id,
			$eprint->get_id ) ) );

	my $datestamp = $eprint->get_value( "lastmod" );
	unless( EPrints::Utils::is_set( $datestamp ) )
	{
		# is this a good default?
		$datestamp = '0001-01-01T00:00:00Z';
	}
	else
	{
		my( $date, $time ) = split( " ", $datestamp );
		$time = "00:00:00" unless defined $time; # Work-around for bad imports
		$datestamp = $date."T".$time."Z";
	}
	$header->appendChild( $session->render_data_element(
		6,
		"datestamp",
		$datestamp ) );

	if( EPrints::Utils::is_set( $oai2 ) )
	{
		if( $eprint->get_dataset()->id() ne "archive" )
		{
			$header->setAttribute( "status" , "deleted" );
			return $header;
		}

		my $viewconf = $session->config( "oai","sets" );
        	foreach my $info ( @{$viewconf} )
        	{
			my @values = $eprint->get_values( $info->{fields} );
			my $afield = EPrints::Utils::field_from_config_string( 
					$eprint->get_dataset(), 
					( split( "/" , $info->{fields} ) )[0] );

			foreach my $v ( @values )
			{
				if( $v eq "" && !$info->{allow_null} ) { next;  }

				my @l;
				if( $afield->is_type( "subject" ) )
				{
					my $subj = new EPrints::DataObj::Subject( $session, $v );
					next unless( defined $subj );
	
					my @paths = $subj->get_paths( 
						$session, 
						$afield->get_property( "top" ) );

					foreach my $path ( @paths )
					{
						my @ids;
						foreach( @{$path} ) 
						{
							push @ids, $_->get_id();
						}
						push @l, encode_setspec( @ids );
					}
				}
				else
				{
					$v = $afield->get_id_from_value( $session, $v );
					@l = ( encode_setspec( $v ) );
				}

				foreach( @l )
				{
					$header->appendChild( $session->render_data_element(
						6,
						"setSpec",
						encode_setspec( $info->{id}.'=' ).$_ ) );
				}
			}
		}
	}

	return $header;
}

######################################################################

sub make_record
{
	my( $session, $eprint, $plugin, $oai2 ) = @_;

	my $record = $session->make_element( "record" );

	my $header = make_header( $session, $eprint, $oai2 );
	$record->appendChild( $session->make_indent( 4 ) );
	$record->appendChild( $header );

	if( $eprint->get_dataset()->id() ne "archive" )
	{
		unless( EPrints::Utils::is_set( $oai2 ) )
		{
			$record->setAttribute( "status" , "deleted" );
		}
		return $record;
	}

	my $md = $plugin->xml_dataobj( $eprint );
	if( defined $md )
	{
		my $metadata = $session->make_element( "metadata" );
		$metadata->appendChild( $session->make_indent( 6 ) );
		$metadata->appendChild( $md );
		# OAI-PMH requires xmlns:xsi be repeated on the <metadata> object, even
		# though it's already declared
		# _setAttribute() is the internal LibXML XS method, so this is very
		# low-level stuff
		if( $md->isa( "XML::LibXML::Element" ) && $md->can( "_setAttribute" ) )
		{
			$md->_setAttribute( "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" );
		}
		$record->appendChild( $session->make_indent( 4 ) );
		$record->appendChild( $metadata );
	}

	return $record;
}

} #end of package patch
