#!/usr/bin/perl
# CLUSTERCLIENT
# Stephen Gould <sgould@stanford.edu>
#
# This script should be started on a cluster machine. It will keep
# checking for commands to execute.
#
# Jobs awaiting execution should be written to "jobsQueued.txt"
# Jobs currently running will be written to "jobsRunning.txt"
# Jobs completed will be written to "jobsCompleted.txt"
#
# The default is for these to be in the user's home directory.
# The client script also processes meta-commands which always start
# with a hash, i.e. #. Current commands are:
#  #join         - wait for all current jobs to complete
#  #wait <hh:mm> - wait until given time (24 hour clock)
#  #file <path>  - wait until file <path> is created
#  #die <n>      - terminate (and decrement counter)
#

use strict;
use Getopt::Std;
use POSIX qw(strftime);
use Sys::Hostname;
use Fcntl ':flock';
use List::Util qw(min max);

my %opts = ();
getopts("hd:m:t:x", \%opts);

if ($opts{h} == 1) {
    print STDERR "USAGE: clusterClient.pl [OPTIONS]\n";
    print STDERR "OPTIONS:\n";
    print STDERR "  -d <dir>     :: directory for jobs files (default: $ENV{HOME})\n";
    print STDERR "  -m <maxjobs> :: maximum number of jobs to execute\n";
    print STDERR "  -t <time>    :: time to wait for next job\n";
    print STDERR "  -x           :: debug model (does not execute jobs)\n";
    print STDERR "\n";
    print STDERR "Use appendJobs.pl to add jobs for processing. Also recognizes the\n";
    print STDERR "following commands:\n";
    print STDERR "  #join        :: waits until all current jobs have finished\n";
    print STDERR "  #wait hh:mm  :: waits until given time (24 hour)\n";
    print STDERR "  #file <path> :: waits until file <path> is created\n";
    print STDERR "  #die <n>     :: terminates up to <n> clients\n";
    print STDERR "\n";
    exit(-1);
}

$opts{d} = $ENV{HOME} unless (defined($opts{d}));
$opts{m} = -1 unless (defined($opts{m}));
$opts{t} = (72 * 60 * 60) unless (defined($opts{t}));

my $JOBSQUEUED = "$opts{d}/jobsQueued.txt";
my $JOBSRUNNING = "$opts{d}/jobsRunning.txt";
my $JOBSFINISHED = "$opts{d}/jobsCompleted.txt";

print STDERR strftime "%H:%M:%S %d-%b-%y: starting client", localtime;
print STDERR " on " . hostname . "\n";

# start job loop
my $startTime = time;
my $jobNum = 0;
while (($opts{m} < 0) || ($jobNum < $opts{m})) {
    # check idle time
    my $timeRemaining = $opts{t} - (time() - $startTime);
    last if ($timeRemaining <= 0);

    # check for new jobs
    if (! -e $JOBSQUEUED) {
        print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
        print STDERR "waiting for job file $JOBSQUEUED to be created\n";
        sleep min(60, max(1, $timeRemaining - 1));
        next;
    }
    if (-z $JOBSQUEUED) {
        print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
        print STDERR "no jobs left in $JOBSQUEUED\n";
        sleep min(60, max(1, $timeRemaining - 1));
        next;
    }

    # lock file and get next job
    open FILE, "+< $JOBSQUEUED" or die "could not open $JOBSQUEUED\n";
    unless (flock FILE, LOCK_EX | LOCK_NB) {
        print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
        print STDERR "waiting for lock\n";
        alarm(min(60, $timeRemaining));
        flock FILE, LOCK_EX or die "could not lock $JOBSQUEUED\n";
        alarm(0);
    }
    my @alljobs = <FILE>;
    if ($#alljobs == -1) {
        truncate FILE, 0;
        close FILE;
        next;
    }

    my $job = shift @alljobs;
    chomp $job;

    # process join command
    if ($job =~ m/^\#join/) {
        if (! -z $JOBSRUNNING) {
            close FILE;
            print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
            print STDERR "waiting for join\n";
            sleep min(60, max(1, $timeRemaining - 1));
            next;
        }

        seek FILE, 0, 0;
        print FILE join("", @alljobs);
        truncate FILE, tell FILE;
        close FILE;
        next;
    }

    # process wait command
    if ($job =~ m/^\#wait\s+(\d+):(\d\d)/) {
        my $t = 60 * $1 + $2;
        my ($sec, $min, $hour) = localtime(time);
        if ($t > (60 * $hour + $min)) {
            close FILE;
            print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
            print STDERR "waiting for time $1:$2\n";
            sleep min(60 * ($t - 60 * $hour - $min), $timeRemaining);
            next;
        }

        seek FILE, 0, 0;
        print FILE join("", @alljobs);
        truncate FILE, tell FILE;
        close FILE;
        next;
    }

#     # process file command
#     if ($job =~ m/^\#wait\s+(\S+)) {
#         my $filename = $1;
#         if (! -e $filename) {
#             close FILE;
#             print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
#             print STDERR "waiting for file $filename\n";
#             sleep min(60, max(1, $timeRemaining - 1));
#             next;
#         }

#         seek FILE, 0, 0;
#         print FILE join("", @alljobs);
#         truncate FILE, tell FILE;
#         close FILE;
#         next;
#     }

    # process die command
    if ($job =~ m/^\#die(\s+(\d+))?/) {
        seek FILE, 0, 0;
        my $num = $1 - 1;
        print FILE "#die $num\n" if ($num > 0);
        print FILE join("", @alljobs);
        truncate FILE, tell FILE;
        close FILE;
        last;
    }

    # write remaining jobs and unlock file
    seek FILE, 0, 0;
    print FILE join("", @alljobs);
    truncate FILE, tell FILE;
    close FILE;

    # execute job
    print STDERR strftime "%H:%M:%S %d-%b-%y: ", localtime;
    print STDERR "executing \"$job\"\n";
    if (!defined($opts{x}) && (length($job) > 0)) {
        # append job to running file
        open FILE, ">> $JOBSRUNNING" or die "could not open $JOBSRUNNING\n";
        flock FILE, LOCK_EX or die "could not lock $JOBSRUNNING\n";
        my $runningLogString = hostname . (strftime "\t%H:%M:%S %d-%b-%y\t", localtime) . $job;
        print FILE "$runningLogString\n";
        close FILE;

        # execute the job
				system($job);
#system($job) == 0
#or die "system $job failed: $?\n";

        # add to completed file and remove job from running file
        open FILE, ">> $JOBSFINISHED" or die "could not open $JOBSFINISHED\n";
        flock FILE, LOCK_EX or die "could not lock $JOBSFINISHED\n";
        print FILE hostname;
        print FILE strftime "\t%H:%M:%S %d-%b-%y\t", localtime;
        print FILE "$job\n";
        close FILE;

        open FILE, "+< $JOBSRUNNING" or die "could not open $JOBSRUNNING\n";
        flock FILE, LOCK_EX or die "could not lock $JOBSRUNNING\n";
        my @allRunningJobs = <FILE>;
        my $foundCommand = 0;
        seek FILE, 0, 0;
        for (my $i = 0; $i <= $#allRunningJobs; $i++) {
            chomp $allRunningJobs[$i];
            if ($allRunningJobs[$i] ne $runningLogString) {
                print FILE "$allRunningJobs[$i]\n";
            } else {
                $foundCommand = 1;
            }
        }
        truncate FILE, tell FILE;
        close FILE;

        print STDERR "could not find job in $JOBSRUNNING\n" unless ($foundCommand);
    }

    # restart idle timer and increment job number
    $startTime = time;
    $jobNum += 1;
}

print STDERR strftime "%H:%M:%S %d-%b-%y: shutting down client after running $jobNum jobs\n", localtime;
