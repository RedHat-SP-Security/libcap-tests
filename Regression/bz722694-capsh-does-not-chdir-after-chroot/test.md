# Setup
1 Create a temporary directory with a subdirectory for chroot

# TMPDIR=$(mktemp -d)  
# CHROOTDIR=$TMPDIR/chroot; mkdir $CHROOTDIR

2\. Install chroot environment

# yum --installroot=$CHROOTDIR -y install bash coreutils

# Test

## Step
1\. Run capssh with chroot and print current dirctory

# capssh --chroot=$CHROOTDIR --  
bash# pwd

## Expect
1\. Current directory is / and you cannot see contents of the above

# Cleanup
1\. in buggy packages current directory is not /
