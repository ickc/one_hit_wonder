use strict;
use warnings;
use File::Spec;
use File::Basename;
use File::Find;

# Function to check if a file is executable by user, group, or others
sub is_executable {
    my $file = shift;
    return ( -f $file || -l $file ) && ( ( lstat($file) )[2] & 0111 );
}

# Function to collect all executable files from the given PATH
sub collect_executables {
    my ($path) = @_;
    my %executables;
    my @dirs = split /:/, $path;

    for my $dir (@dirs) {
        next unless -d $dir;
        find(
            {
                follow => 0,
                wanted => sub {

                    # Skip the root directory itself
                    return if $File::Find::name eq $dir;
                    return unless is_executable($_);
                    $executables{$_} = 1;
                }
            },
            $dir
        );
    }
    return \%executables;
}

# Function to calculate the symmetric difference between two hashes
sub symmetric_difference {
    my ( $execs1, $execs2 ) = @_;

    my %unique1 = map { $_ => 1 } grep { !exists $execs2->{$_} } keys %$execs1;
    my %unique2 = map { $_ => 1 } grep { !exists $execs1->{$_} } keys %$execs2;

    my @result = sort ( keys %unique1, keys %unique2 );
    return @result;
}

# Function to print the results in the specified format
sub print_results {
    my ( $result, $unique1, $unique2 ) = @_;

    foreach my $exe (@$result) {
        if ( exists $unique1->{$exe} ) {
            print "$exe\n";
        }
        else {
            print "\t$exe\n";
        }
    }
}

# Main function to execute the script logic
sub main {
    if ( @ARGV != 2 ) {
        die "Usage: $0 PATH1 PATH2\n";
    }
    my ( $path1, $path2 ) = @ARGV;

    # Collect executables from both paths
    my $execs1 = collect_executables($path1);
    my $execs2 = collect_executables($path2);

    # Get the symmetric difference and sort the results
    my @result = symmetric_difference( $execs1, $execs2 );

    # Print the results in the specified format
    print_results( \@result, $execs1, $execs2 );
}

main();

__END__
