#!/usr/bin/perl
#
# Jeffrey Fall
# VMDK Backup
#
########################################################
# Included Perl Modules
########################################################
use Net::Ping;
use List::Util 'first';


#
############################################################################################
# Purpose: Find Vcenters from Avaamr grid. List hosts on Vcenter(s)
###############################################################################################

#############################################################################################
#Perl subroutines for array operations. Borrowed from ARRAY::Util.pm

sub unique(@) {
        return keys %{ {map { $_ => undef } @_}};
}

sub intersect(\@\@) {
        my %e = map { $_ => undef } @{$_[0]};
        return grep { exists( $e{$_} ) } @{$_[1]};
}

sub array_diff(\@\@) {
        my %e = map { $_ => undef } @{$_[1]};
        return @{[ ( grep { (exists $e{$_}) ? ( delete $e{$_} ) : ( 1 ) } @{ $_[0] } ), keys %e ] };
}

sub array_minus(\@\@) {
        my %e = map{ $_ => undef } @{$_[1]};
        return grep( ! exists( $e{$_} ), @{$_[0]} );
}
#############################################################################################




########################################################################################
# (ATT) Operations team custom section
#
# Edit Variables in this section to reflect the operational enviroment.
#
# For example: add in FQDN's for Avamar Grids, vCenter's and Avamar Proxies
#
########################################################################################
#
#
# Add cloud domain here
$DOMAIN = "cloud";
#
# Add list of vCenter's here. Only one Vcenter is also OK.
# For now the Vcenter server in the VTIL.
# Below is a Perl Array of Vcenters

#NOTE: Below Variable is extracted from the Avamar Grid using a subroutine defined below and called in MAIN
#@VCENTERS = ("cahywr1engvca05.itservices.sbc.com");

# Add list of vCenter's here. Only one Vcenter is also OK.
# For now the Vcenter server in the VTIL.
# Below is a Perl Array of Vcenters
@AVAMAR_GRIDS = ("hx1avu01-rgpn.vtil.cloud.com");

#
# Add list of Avamar Proxies here. Note: Each Proxy can process 8 threads or backups at a time. 
# Proxy servers are stored in a static array. This array should be dynamically filled by a query of proxy servers.
# We statically assert proxy servers from the VTIL
# Below is a perl array of proxies
@PROXIES = ("hlxtil0511.vtil..cloud.com", 
            "hlxtil0537.vtil.cloud.com");
#
########################################################################################
#
#


# perl trim function - remove leading and trailing whitespace
sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}







########################################################################################
# Subroutine: init_envrironment()
########################################################################################
sub init_environment()
{
#print "\nInitializing the $DATACENTER backup vmdk environment\n";
#
# Get the hostname of the Avamar Grid
$HOSTNAME = `hostname`;
$HOSTNAME =~ s/\r\n//; # remove trailing line feed; # remove trailing cr/lf
#
#ping_environment();

return (0);
}
#


########################################################################################
# number of elements in array
##############################################s#########################################
sub num_ele
{
	my $count=0;
	#print "number of elements in array: processing array: @{$_[0]}\n";
	foreach ( @{$_[0]} )
	{
		$count++;
	#	print "$count: $_\n"
	}

	return $count;
}
	



########################################################################################
# get_registered_vcenters  - gets a list of VCenters attached to the Avamar Grid
# via the EMC proxycp.jar. Note: proxycp.jar is not installed on the Avamar Grid by default
# and must be hand installed into a java CLASS_PATH
########################################################################################
sub get_registered_vcenters

{
@registered_vcenters_raw = `/usr/bin/java -jar /usr/local/avamar/lib/proxycp.jar -envinfo`;

my @registered_vcenters = grep /Vcenter Name/, @registered_vcenters_raw;

foreach(@registered_vcenters) 
    { 
$_ =~ s/: //; # Remove ": "
$_ =~ s/Vcenter Name//; # Remove "Vcenter Name"
$_ = trim($_); #remove leading spaces
$_ =~ s/\r\n//;; # remove trailing line feed
    }

return (@registered_vcenters);
}


########################################################################################
# name_filter - filters on a name prefix or suffix 
########################################################################################
sub name_filter

{
my $keyword = ${$_[0]};
my @names_array = @{$_[1]};

#print "Filtering clients on $keyword which may be contained in the hostname...\n\n";

my @filtered_names = grep /$keyword/, @names_array;
return (@filtered_names);
}



########################################################################################
# get_raw_client_output_from_vcenters
########################################################################################

sub get_raw_client_output_from_vcenters

{
	my @vcenters = @{$_[0]};


# Walk the clients in a list of vcenters which is passed in as the first arg  with this mccli command...
# mccli vcenter browse --name=cahywr1engvca05.itservices.sbc.com --type=VM --recursive 
#
# Run the mccli command and Put the output of the command into an array.
#
#

@vcenter_clients = '';

foreach (@vcenters)
  {

print "    Scanning Vcenter  $_ for clients now...\n";
  
#
  @raw_clients = `mccli vcenter browse --name=$_ --type=VM --recursive`;
  push(@vcenter_clients, @raw_clients);
  
  }
  
  print "Returning RAW clients list from all vcenters\n\n";
  
  
return(@vcenter_clients);
	
}






########################################################################################
# get_vcenter_fqdn
# Retturns the whole vCenter FQDN name given the name of the vcenter.
# This is needed in the --domain arg of the mccli add client command
########################################################################################

sub get_vcenter_fqdn

{

my @vcenter = @{$_[0]};
my $vcenter_fqdn = "qwertyasdfg";

foreach (@vcenter)
  {
print "processing vcenter: $_\n";
  my $vcenter_fqdn = first { /$_/ } @registered_vcenters_raw;
  if ($vcenter_fqdn != "qwertyasdfg")
     { 
     	last;
     }
     

  }

print "get_vcenter_fqdn: fqdn of the vcenter = $vcenter_fqdn\n";
}

########################################################################################
# get_clients_from_vcenters
########################################################################################
sub get_clients_from_vcenters
{

# !!!!!!!!!!!!!!!!!!!
# Fix - array needs APPEND for multiple vcenters!!
# !!!!!!!!!!!!!!!!!!!

my @vcenters = @{$_[0]};


# Walk the clients in a list of vcenters which is passed in as the first arg  with this mccli command...
# mccli vcenter browse --name=cahywr1engvca05.itservices.sbc.com --type=VM --recursive 
#
# Run the mccli command and Put the output of the command into an array.
#
#

foreach (@vcenters)
  {

print "    Scanning Vcenter  $_ for clients now...\n";
  @vcenter_clients = '';
#
  @raw_clients = `mccli vcenter browse --name=$_ --type=VM --recursive`;
  splice @raw_clients, 0, 3;
  #print "\n";
#
  $row = 0;
  foreach (@raw_clients) {
        @temp = split(' ',$_);
        #print "$temp[0]\n";
        $vcenter_clients[$row++] = $temp[0];
    }
    pop(@vcenter_clients); # Last element of the array looks to be blank so remove it.
  }
  
 # print "@vcenter_clients";
return(@vcenter_clients);
}











########################################################################################
# *********** MAIN ************ script Main Entry point
######################################################################################## 
#
# Execution begins here.
#
# Call init
print "-----------------------------------------------------------------------------------------\n\n";

my $login = (getpwuid $>);
die "ERROR - not root! This backup vmdk script must run as root. Script halting execution..." if $login ne 'root';
#
print "Step 1) Initializing the Environment...\n";
init_environment();


print "Step 2) Getting list of VCenters registered on Avamar $HOSTNAME";

@VCENTERS = get_registered_vcenters;

    
print "Step 3) Getting list of all clients from VCenters...\n";

@vcenter_clients = get_clients_from_vcenters(\@VCENTERS);

$num_vcenter_clients=num_ele(\@vcenter_clients);
$num_vcenters=num_ele(\@VCENTERS);

#print "@VCENTERS";

print "        Found $num_vcenter_clients client(s) from $num_vcenters vCenter(s)\n\n";

print "List of clients from Vcenter:\n";

foreach (@vcenter_clients)
  {
  print "Vcenter_client = $_\n";
  }

