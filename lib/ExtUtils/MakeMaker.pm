package ExtUtils::MakeMaker;

$Version = 3.4; #Last edited 6th Dec 1994 by Andreas Koenig
$Version; #avoid warning

use Config;
use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &mkbootstrap $Verbose &writeMakefile);
@EXPORT_OK = qw(%att %skip %Recognized_Att_Keys @MM_Sections);

if ($Is_VMS = ($Config{'osname'} eq 'VMS')) {
    require ExtUtils::MM_VMS;
}

use strict qw(refs);
$Verbose = 0;
$^W=1;


=head1 NAME

ExtUtils::MakeMaker - create an extension Makefile

=head1 SYNOPSIS

  use ExtUtils::MakeMaker;
  WriteMakefile("LIBS" => ["-L/usr/alpha -lfoo -lbar"]);

=head1 DESCRIPTION

This utility is designed to write a Makefile for an extension module
from a Makefile.PL. It is based on the Makefile.SH model provided by
Andy Dougherty and the perl5-porters.

It splits the task of generating the Makefile into several subroutines
that can be individually overridden.  Each subroutine returns the text
it wishes to have written to the Makefile.

=head2 Useful Default Makefile Macros
 
FULLEXT = Pathname for extension directory (eg DBD/Oracle).

BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.

ROOTEXT = Directory part of FULLEXT with leading slash (see INST_LIBDIR)

INST_LIBDIR = $(INST_LIB)$(ROOTEXT)

INST_AUTO = $(INST_LIB)/auto/$(FULLEXT)

... others to be added ...

=head2 Customizing The Generated Makefile

If the Makefile generated does not fit your purpose you can change it
using the mechanisms described below.

=head2 Using Attributes (and Parameters)

The following attributes can be specified as arguments to WriteMakefile()
or as NAME=VALUE pairs on the command line:

... not yet written ...

=head2 Overriding MakeMaker Methods

You may specify private subroutines in the Makefile.PL.
Each subroutines returns the text it wishes to have written to
the Makefile. To override a section of the Makefile you can
either say:

	sub MY::c_o { "new literal text" }

or you can edit the default by saying something like:

	sub MY::c_o { $_=MM->c_o; s/old text/new text/; $_ }

If you still need a different solution, try to develop another 
subroutine, that fits your needs and submit the diffs to 
perl5-porters@isu.edu or comp.lang.perl as appropriate.


=head1 AUTHORS

Andy Dougherty <doughera@lafcol.lafayette.edu>, Andreas Koenig
<k@franz.ww.TU-Berlin.DE>, Tim Bunce <Tim.Bunce@ig.co.uk>

=head1 MODIFICATION HISTORY

v1, August 1994; by Andreas Koenig.

Initial version. Based on Andy Dougherty's Makefile.SH work.

v2, September 1994; by Tim Bunce.

Use inheritance to implement overriding.  Methods return text so
derived methods can edit it before it's output.  mkbootstrap() now
executes the *_BS file in the DynaLoader package and automatically adds
dl_findfile() if required. More support for nested modules.

v3.0, October/November 1994; by Tim Bunce.

Major reorganisation. Fixed perl binary locating code. Replaced single
$(TOP) with $(PERL_SRC), $(PERL_LIB) and $(INST_LIB).  Restructured
code.  Consolidated and/or eliminated several attributes and added
argument name checking. Added initial pod documentation. Made generated
Makefile easier to read. Added generic mechanism for passing parameters
to specific sections of the Makefile. Merged in Andreas's perl version
of Andy's extliblist.

v3.1 November 11th 1994 by Tim Bunce

Fixed AIX dynamic loading problem for nested modules. Fixed perl
extliblist to give paths not names for libs so that cross-check works.
Converted the .xs to .c translation to a suffix rule. Added a .xs.o
rule for dumb makes.  Added very useful PM, XS and DIR attributes. Used
new attributes to make other sections smarter (especially clean and
realclean). Make clean no longer deletes Makefile so that a later make
realclean can still work. Fixed all known problems.  Write temporary
Makefile as Makefile.new and rename once complete.

v3.2 November 18th 1994 By Tim Bunce

Fixed typos, added makefile section (split out of a flattened
perldepend section). Added subdirectories to test section. Added -lm
fix for NeXT in extliblist. Added clean of *~ files. Tidied up clean
and realclean sections to produce fewer lines. Major revision to the
const_loadlibs comments for EXTRALIBS, LDLOADLIBS and BSLOADLIBS.
Added LINKTYPE=\$(LINKTYPE) to subdirectory make invocations.
Write temporary Makefile as MakeMaker.tmp. Write temporary xsubpp
output files as xstmp.c instead of tmp. Now installs multiple PM files.
Improved parsing of NAME=VALUE args. $(BOOTSTRAP) is now a dependency
of $(INST_DYNAMIC). Improved init of PERL_LIB, INST_LIB and PERL_SRC.
Reinstated $(TOP) for transition period.  Removed CONFIG_SH attribute
(no longer used). Put INST_PM back and include .pm and .pl files in
current and lib directory.  Allow OBJECT to contain newlines. ROOTEXT
now has leading slash. Added INST_LIBDIR (containing ROOTEXT) and
renamed AUTOEXT to INST_AUTO.  Assorted other cosmetic changes.
All known problems fixed.

v3.3 November 27th 1994 By Andreas Koenig

Bug fixes submitted by Michael Peppler and Wayne Scott. Changed the
order how @libpath is constructed in C<new_extliblist()>. Improved
pod-structure. Relative paths in C<-L> switches to LIBS are turned into
absolute ones now.  Included VMS support thanks to submissions by
Charles Bailey.  Added warnings for switches other than C<-L> or C<-l>
in new_extliblist() and if a library is not found at all. Changed
dependency distclean:clean to distclean:realclean. Added dependency
all->config. ext.libs is now written without duplicates and empty
lines.  As old_extliblist() and new_extliblist() do not produce the
same anymore, the default becomes new_extliblist(), though the warning
remains, whenever they differ. The use of cflags is accompanied by a
replacement: there will be a warning when the two routines lead to
different results, but still the output of cflags will be used.
Cosmetic changes (Capitalize globals, uncapitalize others, insert a
C<:> as default for $postop). Added some verbosity.

v3.4 By Andreas Koenig and Tim Bunce

This patch introduces the variable ARCH_LIB, which defaults to
   $(INST_LIB)/$Config{archname}
All architecture-dependent files will be located below $(ARCH_LIB).
Though the effect is small compared to the effort it made to implement it,
the advantage is unmistakable: people may specify 
  perl Makefile.PL INST_LIB='/usr/local/lib/perl5'
or
  make INST_LIB='$(INSTALLPRIVLIB)' ARCH_LIB='$(INSTALLARCHLIB)'
and get the extension at the right place.
Unfortunately this made it necessary to also patch those:
  ./lib/AutoSplit.pm
  ./installperl
  ./configpm
  ./Makefile.SH
  ./ext/util/make_ext

Further changes:
Updated documentation. AUTOSPLITLIB now does not chdir anymore
and uses autosplit() instead of autosplit_lib_modules(). installpm() now 
makes sure, the target directory exists, that means Kenneth may write
  WriteMakefile( LINKTYPE => "\$(INST_PM)",
  PM => {"Terminfo.pm" => "\$(INST_LIB)/Term/Control/Terminfo/Terminfo.pm"});

Make distclean now removes all Makefiles, not only the one in
$(BASEEXT). Subroutine test() now checks for both t/*.t and test.pl
and writes appropriate entries in Makefile.

Also included are some updates for the VMS support submitted by 
Charles Bailey <bailey@HMIVAX.HUMGEN.UPENN.EDU>.

=head1 NOTES

MakeMaker development work still to be done:

Better Documentation (always true)

Move xsubpp and typemap into lib/ExtUtils/...

The ext.libs file mechanism will need to be revised to allow a
make-a-perl [list-of-static-extensions] script to work.

Eventually eliminate use of $(PERL_SRC) (will require changes elsewhere):

Support C<-R> or C<-Bstatic> on the ld command line in a portable way.

=cut


# Setup dummy package:
# MY exists for overriding methods to be defined within
unshift(@MY::ISA, qw(MM));

# Dummy package MM inherits actual methods from OS-specific
# default packages.  We use this intermediate package so
# MY->func() can call MM->func() and get the proper
# default routine without having to know under what OS
# it's running.
unshift(@MM::ISA, $Is_VMS ? qw(ExtUtils::MM_VMS MM_Unix) : qw(MM_Unix));

$Attrib_Help = <<'END';
 NAME:		Perl module name for this extension (DBD::Oracle)
		This defaults to the directory name.

 DISTNAME:	Your name for distributing the package (by tar file)
		This defaults to NAME above.

 VERSION:	Your version number for distributing the package.
		This defaults to 0.1.

 INST_LIB:	Perl library directory to install the module into.
 ARCH_LIB:	Architecture-dependent part of the library directory.
		This defaults to $(INST_LIB)/$Config{archname}.
 PERL_LIB:	Directory containing the Perl library to use.
 PERL_SRC:	Directory containing the Perl source code
		(use of this should be avoided, it may be removed later)

 INC:		Include file dirs eg: '-I/usr/5include -I/path/to/inc'
 DEFINE:	something like "-DHAVE_UNISTD_H"
 OBJECT:	List of object files, defaults to '$(BASEEXT).o',
		but can be a long string containing all object files,
		    e.g. "tkpBind.o tkpButton.o tkpCanvas.o"
 MYEXTLIB:	If the extension links to a library that it builds
		set this to the name of the library (see SDBM_File)

 LIBS:		An anonymous array of alternative library specifications 
		to be searched for (in order) until at least one library 
		is found.
		    'LIBS' => [ "-L/some/where -ldbm.nfs", "-ldbm" ]
		Mind, that any element of the array contains a complete
		set of arguments for the ld command. So do not specify
		    'LIBS' => ["-ltcl", "-ltk", "-lX11" ], #wrong
		See ODBM_File/Makefile.PL for an example, where an
		array is needed.
		You should know, that if you specify a scalar as in
		    'LIBS' => "-ltcl -ltk -lX11"
		MakeMaker will silently turn it into an array with one
		element.

 LDTARGET:	defaults to "$(OBJECT)" and is used in the ld command
		(some machines need additional switches for bigger projects)

 ARMAYBE:	Defaults to ":", but can be used to run ar before ld

 DIR:		Ref to array of subdirectories containing Makefile.PLs
		e.g. [ 'sdbm' ] in ext/SDBM_File

 PM:		Hashref of .pm files and *.pl files to be installed.
		e.g. { 'name_of_file.pm' => '$(INST_LIBDIR)/install_as.pm' }
		By default this will include *.pm and *.pl. If a lib directory
		exists and is not listed in DIR (above) then any *.pm and
		*.pl files it contains will also be included by default.

 XS:		Hashref of .xs files. MakeMaker will default this.
		e.g. { 'name_of_file.xs' => 'name_of_file.c' }
		The .c files will automatically be included in the list
		of files deleted by a make clean.

 LINKTYPE:	=>'static' or 'dynamic' (default unless usedl=undef in config.sh)
 CONFIG:	=>[qw(archname manext)] defines ARCHNAME & MANEXT from config.sh
 SKIP:  	=>[qw(name1 name2)] skip (do not write) sections of the Makefile

 PERL:
 FULLPERL:

Additional lowercase attributes can be used to pass parameters to the
methods which implement that part of the Makefile. These are not
normally required:

 clean:		{FILES => "*.xyz foo"}
 realclean:	{FILES => "$(INST_AUTO)/*.xyz"}
 distclean:	{TARNAME=>'MyTarFile', TARFLAGS=>'cvfF', COMPRESS=>'gzip'}
 tool_autosplit:	{MAXLEN => 8}
END

@MM_Sections = qw(
    post_initialize
    const_config const_loadlibs
    const_cccmd constants
    tool_autosplit tool_xsubpp tools_other
    post_constants
    c_o xs_c xs_o
    top_targets
    dynamic dynamic_bs dynamic_lib
    static static_lib
    installpm subdirs
    clean realclean distclean test install
    force perldepend makefile postamble
);

%Recognized_Att_Keys = ();
foreach(split(/\n/,$Attrib_Help)){
    chomp;
    next unless m/^\s*(\w+):\s*(.*)/;
    $Recognized_Att_Keys{$1} = $2;
    print "Attribute '$1' => '$2'\n" if ($Verbose >= 2);
}
@Recognized_Att_Keys{@MM_Sections} = @MM_Sections;

%att  = ();
%skip = ();


sub writeMakefile {	# inform about name change till next perl release
    carp "Change &writeMakefile(...) to WriteMakefile(...)\n";
    &WriteMakefile;
}

sub WriteMakefile {
    %att = @_;
    local($\)="\n";

    print STDOUT "MakeMaker" if $Verbose;

    parse_args(\%att, @ARGV);
    my(%initial_att) = %att; # record initial attributes

    MY->initialize(@ARGV);

    print STDOUT "Writing Makefile for $att{NAME}";

    unlink("Makefile", "MakeMaker.tmp", $Is_VMS ? 'Descrip.MMS' : '');
    open MAKE, ">MakeMaker.tmp" or die "Unable to open MakeMaker.tmp: $!";
    select MAKE; $|=1; select STDOUT;

    print MAKE "# This Makefile is for the $att{NAME} extension to perl.\n#";
    print MAKE "# It was written by Makefile.PL, so don't edit it, edit";
    print MAKE "# Makefile.PL instead. ANY CHANGES MADE HERE WILL BE LOST!\n#";
    print MAKE "#   MakeMaker Parameters: ";
    foreach $key (sort keys %initial_att){
	my($v) = neatvalue($initial_att{$key});
	$v =~ tr/\n/ /s;
	print MAKE "#	$key => $v";
    }

    # build hash for SKIP to make testing easy
    %skip = map( ($_,1), @{$att{'SKIP'} || []});

    foreach $section ( @MM_Sections ){
	print "Creating Makefile '$section' section" if ($Verbose >= 2);
	if ($skip{$section}){
	    print MAKE "\n# --- MakeMaker $section section skipped.";
	} else {
	    my(%a) = %{$att{$section} || {}};
	    print MAKE "\n# --- MakeMaker $section section:";
	    print MAKE "# ",%a if ($Verbose >= 2);
	    print(MAKE MY->nicetext(MY->$section( %a )));
	}
    }

    if ($Verbose){
	print MAKE "\n# Full list of MakeMaker attribute values:";
	foreach $key (sort keys %att){
	    my($v) = neatvalue($att{$key});
	    $v =~ tr/\n/ /s;
	    print MAKE "#	$key => $v";
	}
    }

    print MAKE "\n# End.";
    close MAKE;
    my($finalname) = $Is_VMS ? "Descrip.MMS" : "Makefile";
    rename("MakeMaker.tmp", $finalname);

    chmod 0644, $finalname;
    system("$Config{'eunicefix'} $finalname") unless $Config{'eunicefix'} eq ":";

    1;
}


sub mkbootstrap{
    parse_args(\%att, @ARGV);
    MY->mkbootstrap(@_);
}


sub parse_args{
    my($attr, @args) = @_;
    foreach (@args){
	next unless m/(.*?)=(.*)/;
	$$attr{$1} = $2;
    }
    # catch old-style and inform user how to 'upgrade'
    if (defined $$attr{'potential_libs'}){
	my($msg)="'potential_libs' => '$$attr{potential_libs}' should be";
	if ($$attr{'potential_libs'}){
	    print STDERR "$msg changed to 'LIBS' => ['$$attr{potential_libs}']\n";
	} else {
	    print STDERR "$msg deleted.\n";
	}
	$$attr{LIBS} = [$$attr{'potential_libs'}];
	delete $$attr{'potential_libs'};
    }
    foreach(sort keys %{$attr}){
	print STDOUT "	$_ => ".neatvalue($$attr{$_}) if ($Verbose);
	warn "'$_' is not a known MakeMaker parameter name.\n"
	    unless exists $Recognized_Att_Keys{$_};
    }
}


sub neatvalue{
    my($v) = @_;
    my($t) = ref $v;
    return "'$v'" unless $t;
    if ($t eq 'ARRAY') {
      return "[ ".join(', ',map("'$_'",@$v))." ]";
    }
    return "$v" unless $t eq 'HASH';
    my(@m, $key, $val);
    push(@m,"$key=>".neatvalue($val)) while (($key,$val) = each %$v);
    return "{ ".join(', ',@m)." }";
}


# ------ Define the MakeMaker default methods in package MM_Unix ------

package MM_Unix;

use Config;
require Exporter;

Exporter::import('ExtUtils::MakeMaker',
	qw(%att %skip %Recognized_Att_Keys $Verbose));

# These attributes cannot be overridden externally
@Other_Att_Keys{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)} = (1) x 3;

if ($Is_VMS = $Config{'osname'} eq 'VMS') {
    require File::VMSspec;
    import File::VMSspec 'vmsify';
}

sub initialize {
# Find out directory name.  This may also be the extension name.
    my($pwd);
    # This should really just use Cwd.pm
    if ($Is_VMS) {  
	chop($pwd=`Show Default`) ;
    } else {
	chop($pwd=`pwd`);
    } 

    # --- Initialize PERL_LIB, INST_LIB, PERL_SRC

    # This code will need to be reworked to deal with having no perl
    # source.  PERL_LIB should become the primary focus.

    unless ($att{PERL_SRC}){
	foreach(qw(../.. ../../.. ../../../..)){
	    ($att{PERL_SRC}=$_, last) if -f "$_/config.sh";
	}
    }
    unless ($att{PERL_SRC}){
	# Later versions will not die here.
	die "Unable to locate perl source. Try setting PERL_SRC.\n";
	# we should also consider $ENV{PERL5LIB} here
	$att{PERL_LIB} = $Config{'privlib'} unless $att{PERL_LIB};
    } else {
	$att{PERL_LIB} = "$att{PERL_SRC}/lib" unless $att{PERL_LIB};
    }

    $att{INST_LIB} = $att{PERL_LIB} unless $att{INST_LIB};
    $att{ARCH_LIB} = "$att{INST_LIB}/$Config{'archname'}" unless $att{ARCH_LIB};

    # make a few simple checks
    die "PERL_LIB ($att{PERL_LIB}) is not a perl library directory"
	unless (-f "$att{PERL_LIB}/Exporter.pm");

    # --- Initialize Module Name and Paths

    # NAME    = The perl module name for this extension (eg DBD::Oracle).
    # FULLEXT = Pathname for extension directory (eg DBD/Oracle).
    # BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
    # ROOTEXT = Directory part of FULLEXT with leading /.
    unless($att{NAME}){ # we have to guess our name
	my($name) = $pwd;
	if ($Is_VMS) {
	    $name =~ s:.*?([^.\]]+)\]:$1: unless ($name =~ s:.*[.\[]ext\.(.*)\]:$1:i);
	    ($att{NAME} = $name) =~ s#[.\]]#::#g;
	} else {
	    $name =~ s:.*/:: unless ($name =~ s:.*/ext/::);
	    ($att{NAME} = $name) =~ s#/#::#g;
	}
    }
    ($att{FULLEXT} =$att{NAME}) =~ s#::#/#g ;		#eg. BSD/Foo/Socket
    ($att{BASEEXT} =$att{NAME}) =~ s#.*::##;		#eg. Socket
    ($att{ROOTEXT} =$att{FULLEXT}) =~ s#/?\Q$att{BASEEXT}\E$## ; # eg. /BSD/Foo
    $att{ROOTEXT} = ($Is_VMS ? "" : "/").$att{ROOTEXT};

    ($att{DISTNAME}=$att{NAME}) =~ s#(::)#-#g;
    $att{VERSION} = "0.1" unless $att{VERSION};


    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5.
    $att{'PERL'} = MY->find_perl(5.0, [ qw(perl5 perl miniperl) ],
	[ $att{PERL_SRC}, split(":", $ENV{PATH}), $Config{'bin'} ], 0 )
      unless ($att{'PERL'} && -x $att{'PERL'});

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($att{'FULLPERL'} = $att{'PERL'}) =~ s/miniperl/perl/
	unless ($att{'FULLPERL'} && -x $att{'FULLPERL'});

    if ($Is_VMS) {
        # This will not make other Makefile.PLs portable. Any Makefile.PL
        # which says OBJECT => "foo.o bar.o" will fail on VMS. It might
        # be better to fix the c_o section to produce .o files.
	$att{'PERL'} = 'MCR ' . vmsify($att{'PERL'});
	$att{'FULLPERL'} = 'MCR ' . vmsify($att{'FULLPERL'});
    }

    # --- Initialize File and Directory Lists (.xs and .pm)

    {
	my($name, %dir, %xs, %pm);
	foreach $name (lsdir(".")){
	    next if $name =~ /^\./;
	    if (-f "$name/Makefile.PL"){
		$dir{$name} = $name;
	    }elsif ($name =~ /\.xs$/){
		my($c); ($c = $name) =~ s/\.xs$/.c/;
		$xs{$name} = $c;
	    }elsif ($name =~ /\.p[ml]$/ &&
	            !($Is_VMS && $name =~ /makefile.pl/)){
		$pm{$name} = "\$(INST_LIBDIR)/$name";
	    }
	}

	# If we have a ./lib dir that does NOT contain a Makefile.PL
	# then add in any .pm and .pl files in that directory.
	# This makes it easy and tidy to ship a number of perl files.
	if (-d "lib" and !$dir{'lib'}){
	    foreach $name (lsdir("lib")){
		next unless ($name =~ /\.p[ml]$/);
		$pm{"lib/$name"} = "\$(INST_LIBDIR)/$name";
	    }
	}

	$att{DIR} = [sort keys %dir] unless $att{DIRS};
	$att{XS}  = \%xs             unless $att{XS};
	$att{PM}  = \%pm             unless $att{PM};
    }

    # --- Initialize Other Attributes

    for $key (keys(%Recognized_Att_Keys), keys(%Other_Att_Keys)){
	# avoid warnings for uninitialized vars
	next if exists $att{$key};
	$att{$key} = "";
    }

    # Compute EXTRALIBS, BSLOADLIBS and LDLOADLIBS from $att{'LIBS'}
    # Lets look at $att{LIBS} carefully: It may be an anon array, a string or
    # undefined. In any case we turn it into an anon array:
    $att{LIBS}=[] unless $att{LIBS};
    $att{LIBS}=[$att{LIBS}] if ref \$att{LIBS} eq SCALAR;
    foreach ( @{$att{'LIBS'}} ){
	s/^\s*(.*\S)\s*$/$1/; # remove leading and trailing whitespace
	my(@libs) = MY->extliblist($_);
	if ($libs[0] or $libs[1] or $libs[2]){
	    @att{EXTRALIBS, BSLOADLIBS, LDLOADLIBS} = @libs;
	    last;
	}
    }

    warn "CONFIG must be an array ref\n"
	if ($att{CONFIG} and ref $att{CONFIG} ne 'ARRAY');
    $att{CONFIG} = [] unless (ref $att{CONFIG});
    push(@{$att{CONFIG}},
	qw( cc libc ldflags lddlflags ccdlflags cccdlflags
	    ranlib so dlext dlsrc installprivlib installarchlib
	));
    push(@{$att{CONFIG}}, 'shellflags') if $Config{'shellflags'};

    if ($Is_VMS) {
      $att{OBJECT} = '$(BASEEXT).obj' unless $att{OBJECT};
      $att{OBJECT} =~ s/[^,\s]\s+/, /g; $att{OBJECT} =~ s/\n+/, /g;
    } else {
      $att{OBJECT} = '$(BASEEXT).o' unless $att{OBJECT};
      $att{OBJECT} =~ s/\n+/ /g;
    }
    $att{BOOTDEP}  = (-f "$att{BASEEXT}_BS") ? "$att{BASEEXT}_BS" : "";
    $att{LDTARGET} = '$(OBJECT)'    unless $att{LDTARGET};
    unless ($att{LINKTYPE}){
	$att{LINKTYPE} = ($Config{'usedl'}) ? 'dynamic' : 'static';
        #If they are SKIPping the dynamic target we conclude it is static
        if ($att{LINKTYPE} eq 'dynamic') {
            foreach $section (@{$att{'SKIP'} || []}) {
                $att{LINKTYPE} = 'static' if $section eq 'dynamic';
            }
        }
    }
}


sub lsdir{
    local(*DIR, @ls);
    opendir(DIR, $_[0] || ".") or die "opendir: $!";
    @ls = readdir(DIR);
    closedir(DIR);
    @ls;
}


sub find_perl{
    my($self, $ver, $names, $dirs, $trace) = @_;
    my($name, $dir);
    print "Looking for perl $ver by these names: @$names, in these dirs: @$dirs\n"
	if ($trace);
    foreach $dir (@$dirs){
	foreach $name (@$names){
	    print "checking $dir/$name\n" if ($trace >= 2);
	    if ($Is_VMS) {
	      $name .= ".exe" unless -x "$dir/$name";
	    }
	    next unless -x "$dir/$name";
	    print "executing $dir/$name\n" if ($trace);
	    my($out);
	    if ($Is_VMS) {
	      my($vmscmd) = 'MCR ' . vmsify("$dir/$name");
	      $out = `$vmscmd -e "require $ver; print ""VER_OK\n"""`;
	    } else {
	      $out = `$dir/$name -e 'require $ver; print "VER_OK\n" ' 2>&1`;
	    }
	    return "$dir/$name" if $out =~ /VER_OK/;
	}
    }
    warn "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


sub post_initialize{
    "";
}
 

sub constants {
    my(@m);

    push @m, "
.PRECIOUS : Makefile

NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}

# In which library should we install this extension
# this is typically the same as PERL_LIB.
# (also see INST_LIBDIR and relationship to ROOTEXT)
INST_LIB = $att{INST_LIB}
ARCH_LIB = $att{ARCH_LIB}

# Perl library to use when building the extension
PERL_LIB = $att{PERL_LIB}
# Where is the perl source code located (eventually we should
# be able to build extensions without requiring the perl source
# but that's a long way off yet).
PERL_SRC = $att{PERL_SRC}
# Perl header files (will eventually be under PERL_LIB)
PERL_INC = $att{PERL_SRC}
# Perl binaries
PERL = $att{'PERL'}
FULLPERL = $att{'FULLPERL'}

# TOP will be removed in a later version. Use PERL_SRC instead.
TOP = \$(PERL_SRC)

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT with leading slash (see INST_LIBDIR)
FULLEXT = $att{FULLEXT}
BASEEXT = $att{BASEEXT}
ROOTEXT = $att{ROOTEXT}

INC = $att{INC}
DEFINE = $att{DEFINE}
OBJECT = $att{OBJECT}
LDTARGET = $att{LDTARGET}
LINKTYPE = $att{LINKTYPE}

.SUFFIXES: .xs

# This extension may link to it's own library (see SDBM_File)
MYEXTLIB = $att{MYEXTLIB}

";

    push @m, '
# Where to put things:
INST_LIBDIR = $(INST_LIB)$(ROOTEXT)
INST_AUTO = $(ARCH_LIB)/auto/$(FULLEXT)
INST_BOOT = $(INST_AUTO)/$(BASEEXT).bs
INST_DYNAMIC = $(INST_AUTO)/$(BASEEXT).$(DLEXT)
INST_STATIC = $(BASEEXT).a
INST_PM = '.join(" ", sort values %{$att{PM}}).'
';

    join('',@m);
}


sub const_cccmd{
    # This is implemented in the
    # same manner as extliblist, e.g., do both and compare results during
    # the transition period.
    my($cc,$ccflags,$optimize,$large,$split)=@Config{qw(cc ccflags optimize large split)};
    my($prog);
    chop(my($old) = `cd $att{PERL_SRC}; sh $Config{'shellflags'} ./cflags $att{BASEEXT}.c`);
    if ($prog = $Config{"$att{BASEEXT}_cflags"}) {
	my(@o)=`cc=\"$cc\"
        ccflags=\"$ccflags\"
        optimize=\"$optimize\"
        large=\"$large\"
        split=\"$split\"
        eval '$prog'
        echo cc=\$cc
        echo ccflags=\$ccflags
        echo optimize=\$optimize
        echo large=\$large
        echo split=\$split
        `;
	my(%cflags);
	foreach $line (@o){
	    chomp $line;
	    if ($line =~ /(.*?)\s*=\s*(.*)\s*$/){
		$cflags{$1} = $2;
		print STDERR "	$1 = $2" if $Verbose;
	    }
	}
	($cc,$ccflags,$optimize,$large,$split)=@cflags{qw(cc ccflags optimize large split)};
    }
    my($new) = "$cc -c $ccflags $optimize  $large $split";
    if ($new ne $old) {
	warn "Warning (non-fatal): cflags evaluation in MakeMaker differs from shell output\n"
      ."   package: $att{NAME}\n"
      ."   old: $old\n"
      ."   new: $new\n"
      ."   Using 'old' set.\n"
      ."Please notify perl5-porters\@isu.edu\n";
    }
    my($cccmd)=$old;
    "CCCMD = $cccmd\n";
}


# --- Constants Sections ---

sub const_config{
    my(@m,$m);
    push(@m,"\n# These definitions are taken from config.sh (via Config.pm)\n");
    my(%once_only);
    foreach $m (@{$att{'CONFIG'}}){
	next if $once_only{$m};
	warn "CONFIG key '$m' does not exist in Config.pm\n"
		unless exists $Config{$m};
	push @m, "\U$m\E = $Config{$m}\n";
	$once_only{$m} = 1;
    }
    join('', @m);
}


sub const_loadlibs{
    "
# $att{NAME} might depend on some other libraries:
# (These comments may need revising:)
#
# Dependant libraries are linked in one of three ways:
#
#  1.  (For static extensions) by the ld command when
#      the perl binary is linked with the extension library.
#      See EXTRALIBS below.
#
#  2.  (For dynamic extensions) by the ld command when
#      the shared object is built/linked.
#      See LDLOADLIBS below.
#
#  3.  (For dynamic extensions) by the DynaLoader when
#      the shared object is loaded.
#      See BSLOADLIBS below.
#
# EXTRALIBS =	List of libraries that need to be linked with when
#		linking a perl binary which includes this extension
#		Only those libraries that actually exist are included.
#
# LDLOADLIBS =	List of those libraries which must be statically
#		linked into the shared library.  On SunOS 4.1.3, 
#		for example,  I have only an archive version of -lm,
#		and it must be linked in statically.
#
# BSLOADLIBS =	List of those libraries that are needed but can be
#		linked in dynamically on this platform.  On SunOS, for
#		example, this would be .so* libraries, but not archive
#		libraries.  The bootstrap file is installed only if
#		this list is not empty.
#
EXTRALIBS  = $att{'EXTRALIBS'}
LDLOADLIBS = $att{'LDLOADLIBS'}
BSLOADLIBS = $att{'BSLOADLIBS'}
";
}


# --- Tool Sections ---

sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = $attribs{MAXLEN} || 8;
    q{
AUTOSPLITLIB = $(PERL) -I$(ARCH_LIB) -I$(PERL_LIB) -e 'use AutoSplit; $$AutoSplit::Maxlen=}.$asl.q{; autosplit(@ARGV) ;'
};
}


sub tool_xsubpp{
    my(@tmdeps) = ('$(PERL_SRC)/ext/typemap');
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    "
XSUBPP = \$(PERL_SRC)/ext/xsubpp
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
};


sub tools_other{
    q{
SHELL = /bin/sh

# The following is a portable way to say mkdir -p
MKPATH = $(PERL) -we '$$"="/"; foreach(split(/\//,$$ARGV[0])){ push(@p, $$_); next if -d "@p" or "@p" eq ""; print "mkdir @p\n"; mkdir("@p",0777)||die "mkdir @p: $$!" } exit 0;'
};
}


sub post_constants{
    "";
}


# --- Target Sections ---


sub top_targets{
    '
all ::	$(LINKTYPE) config

config :: Makefile
	@$(MKPATH) $(INST_AUTO)
	@$(MKPATH) $(INST_LIBDIR)

install :: all
';
}



# --- Dynamic Loading Sections ---

sub dynamic {
    if ($skip{'dynamic_lib'}) {
	warn "Warning (non-fatal): Target 'dynamic' depends on targets in skipped section 'dynamic_lib'\n";
    }
    if ($skip{'dynamic_bs'}) {
	warn "Warning (non-fatal): Target 'dynamic' depends on targets in skipped section 'dynamic_bs'\n";
    }
    "
dynamic :: \$(INST_DYNAMIC) \$(INST_BOOT) \$(INST_PM)
";
}

sub dynamic_bs {
    my($self, %attribs) = @_;
    '
BOOTSTRAP = '."$att{BASEEXT}.bs".'

# As MakeMaker mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The $(INST_BOOT) target below will only install a non-empty file.
$(BOOTSTRAP): '.$att{BOOTDEP}.' $(ARCH_LIB)/Config.pm
	$(PERL) -I$(ARCH_LIB) -I$(PERL_LIB) -e \'use ExtUtils::MakeMaker; &mkbootstrap("$(BSLOADLIBS)");\' INST_LIB=$(INST_LIB) PERL_SRC=$(PERL_SRC) NAME=$(NAME)
	@touch $(BOOTSTRAP)

$(INST_BOOT): $(BOOTSTRAP)
	@rm -f $(INST_BOOT)
	test -s $(BOOTSTRAP) && cp $(BOOTSTRAP) $(INST_BOOT) || true
';
}

sub dynamic_lib {
    my($self, %attribs) = @_;
    my($otherldflags) = $attribs{OTHERLDLFLAGS} || "";
    $att{ARMAYBE} = ":" unless $att{ARMAYBE};
    if ($skip{'dynamic_bs'}) {
	warn "Warning (non-fatal): Target '$(INST_DYNAMIC)' depends on targets in skipped section 'dynamic_bs'\n";
    }
    '
ARMAYBE = '.$att{ARMAYBE}.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP)
	@$(MKPATH) $(INST_AUTO)
	$(ARMAYBE) cr $(BASEEXT).a $(OBJECT) 
	ld $(LDDLFLAGS) -o $@ $(LDTARGET) '.$otherldflags.' $(MYEXTLIB) $(LDLOADLIBS)
';
}


# --- Static Loading Sections ---

sub static {
    if ($skip{'static_lib'}) {
	warn "Warning (non-fatal): Target 'static' depends on targets in skipped section 'static_lib'\n";
    }
    "
static :: \$(INST_STATIC) \$(INST_PM)
";
}

sub static_lib{
    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB)
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) to it.
    push(@m, '	cp $(MYEXTLIB) $@'."\n") if $att{MYEXTLIB};

# This is not a complete solution for ext.libs and it may break on
# parallel builds. See to-do section at top of this file.
    push(@m, <<'END');
	ar cr $@ $(OBJECT)
	$(RANLIB) $@
	@$(PERL) -e '$$E="$(PERL_SRC)/ext.libs";open E, $$E;@E=<E>;$$_="@E" . " $(EXTRALIBS)"; @O=split; @O{@O}=@O; $$\=$$,="\n";open E, ">$$E"; print E sort keys %O;'
END
    join('', "\n",@m);
}


sub installpm {
    my($self, %attribs) = @_;
    my(@m, $dist);
    push(@m, "\n# the config target will MKPATH \$(INST_LIBDIR)\n");
    foreach $dist (sort keys %{$att{PM}}){
	my($inst) = $att{PM}->{$dist};
	( my($instdir) ) = $inst =~ m|(.*)/|;
	push(@m, "
$inst: $dist
".'	@rm -f $@
	@test -d '.$instdir.' || echo Making directory '.$instdir.'
	@test -d '.$instdir.' || $(MKPATH) '.$instdir.'
	cp $? $@
');
	push(@m, '	$(AUTOSPLITLIB) $@ $(ARCH_LIB)/auto'."\n")
	    if ($dist =~ /\.pm$/);
	push(@m,"\n");
    }

    join('', @m);
}


# --- Translation Sections ---

sub c_o {
    '
.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}

sub xs_c {
    '
.xs.c:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $@
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    '
.xs.o:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >xstmp.c && mv xstmp.c $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}


# --- Sub-directory Sections ---

sub subdirs {
    my(@m);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach(<*/Makefile.PL>){
	s:/Makefile\.PL$:: ;
	print "Including $_ subdirectory" if ($Verbose);
	push @m, MY->subdir_x($_);
    }
    join('',@m);
}

sub runsubdirpl{	# Experimental! See subdir_x section
    my($self,$subdir) = @_;
    chdir($subdir) or die "chdir($subdir): $!";
    require "Makefile.PL";
}

sub subdir_x {
    my($self, $subdir) = @_;
    my(@m);
    # The intention is that the calling Makefile.PL should define the
    # $(SUBDIR_MAKEFILE_PL_ARGS) make macro to contain whatever
    # information needs to be passed down to the other Makefile.PL scripts.
    # If this does not suit your needs you'll need to write your own
    # MY::subdir_x() method to override this one.
    qq{
config :: $subdir/Makefile
	cd $subdir ; \$(MAKE) config LINKTYPE=\$(LINKTYPE)

$subdir/Makefile: $subdir/Makefile.PL \$(ARCH_LIB)/Config.pm
}.'	@echo "Rebuilding $@ ..."
	$(PERL) -I$(ARCH_LIB) -I$(PERL_LIB) \\
		-e "use ExtUtils::MakeMaker; MM->runsubdirpl(qw('.$subdir.'))" \\
		$(SUBDIR_MAKEFILE_PL_ARGS)
	@echo "Rebuild of $@ complete."
'.qq{

# The default clean, realclean and test targets in this Makefile
# have automatically been given entries for $subdir.

all ::
	cd $subdir ; \$(MAKE) all LINKTYPE=\$(LINKTYPE)

};
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, '
# Delete temporary files but do not touch installed files. We don\'t delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
');
    foreach(@{$att{DIR}}){ # clean subdirectories first
	push(@m, "\t-cd $_ && test -f Makefile && \$(MAKE) clean\n");
    }
    push(@m, "	rm -f *~ t/*~ *.o *.a mon.out core so_locations \$(BOOTSTRAP) \$(BASEEXT).bso\n");
    my(@otherfiles);
    # Automatically delete the .c files generated from *.xs files:
    push(@otherfiles, values %{$att{XS}});
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	rm -rf @otherfiles\n") if @otherfiles;
    push(@m, "	$attribs{POSTOP}\n")   if $attribs{POSTOP};
    join("", @m);
}

sub realclean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m,'
# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
');
    foreach(@{$att{DIR}}){ # clean subdirectories first
	push(@m, "\t-cd $_ && test -f Makefile && \$(MAKE) realclean\n");
    }
    push(@m, '	rm -f Makefile $(INST_DYNAMIC) $(INST_STATIC) $(INST_BOOT) $(INST_PM)'."\n");
    push(@m, '	rm -rf $(INST_AUTO)'."\n");
    my(@otherfiles);
    push(@otherfiles, $attribs{FILES}) if $attribs{FILES};
    push(@m, "	rm -rf @otherfiles\n") if @otherfiles;
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}


sub distclean {
    my($self, %attribs) = @_;
    # VERSION should be sanitised before use as a file name
    my($tarname)  = $attribs{TARNAME}  || '$(DISTNAME)-$(VERSION)';
    my($tarflags) = $attribs{TARFLAGS} || 'cvf';
    my($compress) = $attribs{COMPRESS} || 'compress'; # eg gzip
    my($postop)   = $attribs{POSTOP} || ":";
    my(@m);
    push @m, "
distclean:     clean";
    foreach(@{$att{DIR}},"."){
	push(@m, "
	rm -f $_/Makefile");
    }
    push @m, "
	cd ..; tar $tarflags $tarname.tar \$(BASEEXT)
	cd ..; $compress $tarname.tar
	$postop
";
    join("", @m);
}


# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || (-d "t" ? "t/*.t" : "");
    my(@m);
    push(@m,"
test :: all
");
    push(@m,"
	\$(FULLPERL) -I\$(ARCH_LIB) -I\$(PERL_LIB) -e 'use Test::Harness; runtests \@ARGV;' $tests
") if $tests;
    push(@m,"
	\$(FULLPERL) -I\$(ARCH_LIB) -I\$(PERL_LIB) test.pl
") if -f test.pl;
    foreach(@{$att{DIR}}){
	push(@m, "	cd $_ && test -f Makefile && \$(MAKE) test LINKTYPE=\$(LINKTYPE)\n");
    }
    join("", @m);
}


sub install {
    '
install :: all
	# Not defined. Makefile, by default, builds the extension directly
	# into $(INST_LIB) so "installing" does not make much sense.
	# If INST_LIB is in the perl source tree then installperl will
	# install the extension when it installs perl.
';
}


sub force {
    '# Phony target to force checking subdirectories.
FORCE:
';
}


sub perldepend {
    '
PERL_HDRS = $(PERL_INC)/EXTERN.h $(PERL_INC)/INTERN.h \
    $(PERL_INC)/XSUB.h	$(PERL_INC)/av.h	$(PERL_INC)/cop.h \
    $(PERL_INC)/cv.h	$(PERL_INC)/dosish.h	$(PERL_INC)/embed.h \
    $(PERL_INC)/form.h	$(PERL_INC)/gv.h	$(PERL_INC)/handy.h \
    $(PERL_INC)/hv.h	$(PERL_INC)/keywords.h	$(PERL_INC)/mg.h \
    $(PERL_INC)/op.h	$(PERL_INC)/opcode.h	$(PERL_INC)/patchlevel.h \
    $(PERL_INC)/perl.h	$(PERL_INC)/perly.h	$(PERL_INC)/pp.h \
    $(PERL_INC)/proto.h	$(PERL_INC)/regcomp.h	$(PERL_INC)/regexp.h \
    $(PERL_INC)/scope.h	$(PERL_INC)/sv.h	$(PERL_INC)/unixish.h \
    $(PERL_INC)/util.h

$(PERL_INC)/config.h: $(PERL_SRC)/config.sh; cd $(PERL_SRC); /bin/sh config_h.SH
$(PERL_INC)/embed.h:  $(PERL_SRC)/config.sh; cd $(PERL_SRC); /bin/sh embed_h.SH

$(OBJECT) : $(PERL_HDRS)
';
}


sub makefile {
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it would only
    # happen very rarely it is not a significant problem.
    '
$(OBJECT) : Makefile

Makefile:	Makefile.PL $(ARCH_LIB)/Config.pm
	$(PERL) -I$(ARCH_LIB) -I$(PERL_LIB) Makefile.PL
	@echo "Now you must rerun make"; false
';
}


sub postamble{
    "";
}


# --- Determine libraries to use and how to use them ---

sub extliblist{
    my($self, $libs) = @_;
    return ("", "", "") unless $libs;
    print STDERR "Potential libraries are '$libs':" if $Verbose;
    my(@old) = MY->old_extliblist($libs);
    my(@new) = MY->new_extliblist($libs);

    my($oldlibs) = join(" : ",@old);
    my($newlibs) = join(" : ",@new);
    warn "Warning (non-fatal): $att{NAME} extliblist consistency check failed:\n".
	"  old: $oldlibs\n".
	"  new: $newlibs\n".
	"Using 'new' set. Please notify perl5-porters\@isu.edu.\n"
	    if "$newlibs" ne "$oldlibs";
    @new;
}


sub old_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;

    my(%attrib, @w);
    # Now run ext/util/extliblist to discover what *libs definitions
    # are required for the needs of $potential_libs
    $ENV{'potential_libs'} = $potential_libs;
    my(@o)=`. $att{PERL_SRC}/config.sh
	    . $att{PERL_SRC}/ext/util/extliblist;
	    echo EXTRALIBS=\$extralibs
	    echo BSLOADLIBS=\$dynaloadlibs
	    echo LDLOADLIBS=\$statloadlibs
	    `;
    foreach $line (@o){
	chomp $line;
	if ($line =~ /(.*)\s*=\s*(.*)\s*$/){
	    $attrib{$1} = $2;
	    print STDERR "	$1 = $2" if $Verbose;
	}else{
	    push(@w, $line);
	}
    }
    print STDERR "Messages from extliblist:\n", join("\n",@w,'')
       if @w ;
    @attrib{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)};
}


sub new_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;

    my($so)   = $Config{'so'};
    my($libs) = $Config{'libs'};

    # compute $extralibs, $bsloadlibs and $ldloadlibs from
    # $potential_libs
    # this is a rewrite of Andy Dougherty's extliblist in perl
    # its home is in <distribution>/ext/util

    my(@searchpath); # from "-L/path" entries in $potential_libs
    my(@libpath) = split " ", $Config{'libpth'};
    my(@ldloadlibs);
    my(@bsloadlibs);
    my(@extralibs);
    my($fullname);

    chop(my($pwd)=`pwd`);

    foreach $thislib (split ' ', $potential_libs){

	# Handle possible linker path arguments.
	if ($thislib =~ s/^-L//){
	    unless (-d $thislib){
		warn "-L$thislib ignored, directory does not exist\n"
			if $Verbose;
		next;
	    }
	    if ($thislib !~ m|^/|) {
	      warn "Warning: -L$thislib changed to -L$pwd/$thislib\n";
	      $thislib = "$pwd/$thislib";
	    }
	    push(@searchpath, $thislib);
	    push(@extralibs,  "-L$thislib");
	    push(@ldloadlibs, "-L$thislib");
	    if (
		$Config{'osname'} eq "sunos" && $Config{'osvers'} ge "4_1"
		|| $Config{'osname'} eq "solaris"
		) {
	      push(@ldloadlibs, "-R$thislib");
	    }
	    next;
	}

	# Handle possible library arguments.
	unless ($thislib =~ s/^-l//){
	  warn "Unrecognized argument in LIBS ignored: $thislib\n";
	  next;
	}
	my($found_lib)=0;
	foreach $thispth (@searchpath, @libpath){

	    if (@fullname=<${thispth}/lib${thislib}.${so}.[0-9]*>){
		$fullname=$fullname[-1]; #ATTN: 10 looses against 9!
	    } elsif (-f ($fullname="$thispth/lib$thislib.$so")){
	    } elsif (-f ($fullname="$thispth/lib${thislib}_s.a")){
	    } elsif (-f ($fullname="$thispth/lib$thislib.a")){
	    } elsif (-f ($fullname="$thispth/Slib$thislib.a")){
	    } else { 
		warn "$thislib not found in $thispth\n" if $Verbose;
		next;
	    }
	    warn "'-l$thislib' found at $fullname\n" if $Verbose;
	    $found_lib++;

	    # Now update library lists

	    # what do we know about this library...
	    my $is_dyna = ($fullname !~ /\.a$/);
	    my $in_perl = ($libs =~ /\B-l${thislib}\b|\B-l${thislib}_s\b/s);

	    # Do not add it into the list if it is already linked in
	    # with the main perl executable.
	    # We have to special-case the NeXT, because all the math is also in libsys_s
	    unless ( $in_perl || ($Config{'osname'} eq 'next' && $thislib eq 'm') ){
		push(@extralibs, "-l$thislib");
	    }
			

	    # We might be able to load this archive file dynamically
	    if ( $Config{'dlsrc'} =~ /dl_next|dl_dld/){
		# We push -l$thislib instead of $fullname because
		# it avoids hardwiring a fixed path into the .bs file.
		# mkbootstrap will automatically add dl_findfile() to
		# the .bs file if it sees a name in the -l format.
		# USE THIS LATER: push(@bsloadlibs, "-l$thislib"); # " $fullname";
		# USE THIS while checking results against old_extliblist
		push(@bsloadlibs, "$fullname");
	    } else {
		if ($is_dyna){
                    # For SunOS4, do not add in this shared library if
                    # it is already linked in the main perl executable
		    push(@ldloadlibs, "-l$thislib")
			unless ($in_perl and $Config{'osname'} eq 'sunos');
		} else {
		    push(@ldloadlibs, "-l$thislib");
		}
	    }
	    last;	# found one here so don't bother looking further
	}
	warn "Warning (non-fatal): No library found for -l$thislib\n" unless $found_lib>0;
    }
    ("@extralibs", "@bsloadlibs", "@ldloadlibs");
}


# --- Write a DynaLoader bootstrap file if required

sub mkbootstrap {

=head1 NAME

mkbootstrap

=head1 DESCRIPTION

Make a bootstrap file for use by this system's DynaLoader.
It typically gets called from an extension Makefile.

There is no .bs file supplied with the extension. Instead a _BS file
which has code for the special cases, like posix for berkeley db on the
NeXT.

This file will get parsed, and produce a maybe empty
@DynaLoader::dl_resolve_using array for the current architecture.
That will be extended by $BSLOADLIBS, which was computed by Andy's
extliblist script. If this array still is empty, we do nothing, else
we write a .bs file with an @DynaLoader::dl_resolve_using array, but
without any C<if>s, because there is no longer a need to deal with
special cases.

The _BS file can put some code into the generated .bs file by placing
it in $bscode. This is a handy 'escape' mechanism that may prove
useful in complex situations.

If @DynaLoader::dl_resolve_using contains C<-L*> or C<-l*> entries then
mkbootstrap will automatically add a dl_findfile() call to the
generated .bs file.

=head1 AUTHORS

Andreas Koenig <k@otto.ww.TU-Berlin.DE>, Tim Bunce
<Tim.Bunce@ig.co.uk>, Andy Dougherty <doughera@lafcol.lafayette.edu>

=cut

    my($self, @bsloadlibs)=@_;

    @bsloadlibs = grep($_, @bsloadlibs); # strip empty libs

    print STDERR "	bsloadlibs=@bsloadlibs\n" if $Verbose;

    # We need DynaLoader here because we and/or the *_BS file may
    # call dl_findfile(). We don't say `use' here because when
    # first building perl extensions the DynaLoader will not have
    # been built when MakeMaker gets first used.
    require DynaLoader;
    import DynaLoader;

    initialize(@ARGV) unless defined $att{'BASEEXT'};

    rename "$att{BASEEXT}.bs", "$att{BASEEXT}.bso";

    if (-f "$att{BASEEXT}_BS"){
	$_ = "$att{BASEEXT}_BS";
	package DynaLoader; # execute code as if in DynaLoader
	local($osname, $dlsrc) = (); # avoid warnings
	($osname, $dlsrc) = @Config::Config{qw(osname dlsrc)};
	$bscode = "";
	unshift @INC, ".";
	require $_;
	shift @INC;
    }

    if ($Config{'dlsrc'} =~ /^dl_dld/){
	package DynaLoader;
	push(@dl_resolve_using, dl_findfile('-lc'));
    }

    my(@all) = (@bsloadlibs, @DynaLoader::dl_resolve_using);
    my($method) = '';
    if (@all){
	open BS, ">$att{BASEEXT}.bs"
		or die "Unable to open $att{BASEEXT}.bs: $!";
	print STDOUT "Writing $att{BASEEXT}.bs\n";
	print STDOUT "	containing: @all" if $Verbose;
	print BS "# $att{BASEEXT} DynaLoader bootstrap file for $Config{'osname'} architecture.\n";
	print BS "# Do not edit this file, changes will be lost.\n";
	print BS "# This file was automatically generated by the\n";
	print BS "# mkbootstrap routine in ExtUtils/MakeMaker.pm.\n";
	print BS "\@DynaLoader::dl_resolve_using = ";
	# If @all contains names in the form -lxxx or -Lxxx then it's asking for
	# runtime library location so we automatically add a call to dl_findfile()
	if (" @all" =~ m/ -[lL]/){
	    print BS "  dl_findfile(qw(\n  @all\n  ));\n";
	}else{
	    print BS "  qw(@all);\n";
	}
	# write extra code if *_BS says so
	print BS $DynaLoader::bscode if $DynaLoader::bscode;
	print BS "\n1;\n";
	close BS;
    }

    # special handling for systems which needs a list of all global
    # symbols exported by a modules to be dynamically linked.
    if ($Config{'dlsrc'} =~ /^dl_aix/){
       my($bootfunc);
       ($bootfunc = $att{NAME}) =~ s/\W/_/g;
       open EXP, ">$att{BASEEXT}.exp";
       print EXP "#!\nboot_$bootfunc\n";
       close EXP;
    }
}


# --- Output postprocessing section ---
#nicetext is included to make VMS support easier
sub nicetext { # Just return the input - no action needed
    my($self,$text) = @_;
    $text;
}
 
# the following keeps AutoSplit happy
package ExtUtils::MakeMaker;
1;

__END__
