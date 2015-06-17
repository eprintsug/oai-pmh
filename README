# OAI-PMH update

**a pull request has been submitted to bring this change into the core EPrints:**
https://github.com/eprints/eprints/pull/324


## Installation

Install the package from the Bazaar http://bazaar.eprints.org/411/ :sunglasses: - or copy:

 * lib/cfg.d/zz_oaipmh_patch_core_EPrints_OpenArchives.pl to ~/lib/cfg.d/
 * cgi/oai2 to ~/archives/ARCHIVEID/cgi/oai2 


**WARNING:**

If manually installing, do not copy cgi/oai2 without first copying `zz_oaipmh_patch_core_EPrints_OpenArchives.pl`.

Without the patch to EPrints::OpenArchives, metadata for 
records not in the archive will be available to harvest. 

## Implementation

The changes to `cgi/oai2` code will change the default filter for OAI-PMH records from 'in archive OR deletion':

```perl
push @$filters, {
    meta_fields => [qw( eprint_status )],
    value => "archive deletion",
    match => "EQ",
    merge => "ANY",
};
```

 to 'has datestamp': 

```perl
push @$filters, {
    meta_fields => [qw( datestamp )],
    match => "SET",
};
```

Any record with a datestamp, that is not in the live 'archive' dataset will be reported as 'deleted' over OAI-PMH.

## Changes

 * 1.00 John Salter <j.salter@leeds.ac.uk>
   
   Initial version

