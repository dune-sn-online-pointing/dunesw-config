# Quick guide of commonly used commands in git

Feel free to add more commands to this list.

## clone 

When cloning, use the following commands.

<remote_repo> refers to the HTTPS link of the repo to clone. 
It has to end with `.git`.
For this repo, the command is:
    
```bash
git clone https://git.t2k.org/tof_utils/recontruction/tof-reco.git
```

To clone a specific branch (knowing that one cloned you can always move between different branches).

```bash
git clone -b <branch> <remote_repo>
```
It can also work to clone a specific tag (knowing that one cloned you can always move between different tags).
    
```bash 
git clone -b <tag> <remote_repo>
```

## Checkout to a tagged version, apply changes

If you want to checkout to a tagged version, you can do it with:
```
git checkout tags/v2.0.0
```

You will now be in detached state, so to operate changes do the following:
```
git checkout [-b] mybranch
```
the `-b` flag is needed only if you want to create a new branch, otherwise you can just checkout to an existing one.
Once the branch is ready to be merged into main, compile a merge request.


## pull commands

To pull changes, use the following commands.

```bash
git pull
```

Sometimes you might want to pull changes from a specific branch or tag.
    
```bash
git pull origin <branch>
```

```bash
git pull origin <tag>
```

You might also want to force pull, meaning overwriting your local changes in case you don't want to keep them.

```bash
git fetch --all
git reset --hard origin/<branch>
```

MAKE SURE YOU DON'T CARE ABOUT WHAT YOU WERE WORKING ON, otherwise stash or commit it before.


## commit-add-push commands

### New branch

When working, it is recommended to create a new branch for a specific feature or function or bug fix.
The name of the branch shall be informative, possibly containing your name and/or the feature you are working on.
Example: `feature/fix-bug-1234` or `evilla/develop`.

To create the new branch  you can use the following command:

```bash
git checkout -b <branch_name>
```

### add

To add all the changes you made to the staging area, use the following command:

```bash
git add .
```
 
Note that this command will add everything in the current directory and its subdirectories. 
Therefore, if you run it from a subdirectory, it will add only the files in that subdirectory and its subdirectories, not the level above.
If you want to add only specific files, you can use the following command:

```bash
git add <file1> <file2> <file3> ...
```
To remove some files from the directory, you can use the following command:

```bash
git rm <file1> <file2> <file3> ...
```

Instead, if you delete or move files in the repo and you want this to be reflected in the staging area, you can use the following command:

```bash
git add -u
```

### commit

To commit the changes you added to the staging area, use the following command:

```bash
git commit -m "Your commit message here"
```
Try and commit often, so that the message can shortly describe the changes that you made. 
If you commit after a lot of changes, it's more difficult to keep track and possibly go back.

### push

To push the changes you committed to the remote repository, the first time you have to use the following command:

```bash
git push origin <branch_name>
```

Then, once the branch is pushed, you can just:

```bash
git push
```
### stash 

Stashing is a way of saving the changes without committing them, that can be useful in some cases.
Don't do it if you're not very confident with git.
If you want to stash your changes, you can use the following commands:

```bash
git stash
```


## Merge request

Once you are ready to merge your branch into the main branch, you can create a merge request.
Go to the repository page, click on the `Merge request` tab, and create a new merge request.
In this repo it's here: https://git.t2k.org/tof_utils/reconstruction/tof-reco/-/merge_requests. 
In GitHub they are called `Pull requests` instead.
Select the branch you want to merge from and the branch you want to merge into.
Add a title and a description, and assign the merge request to someone for review.
Once the merge request is approved, you can merge the branch into the main branch.

If there are conflicts, they can be resolved by the reviewer or by the author of the merge request.
If they are not significant, normally there's a web interface, otherwise you'll have to do it through an editor like VS, that has nice extensions for this.


## Rebase

Rebasing means changing the base of your branch to another branch, or to get rid of some commits and go back to a certain version of the code.
If you want to rebase your branch on the main branch, you can use the following commands:

```bash
git checkout main
git pull
git checkout <branch_name>
git rebase main
```

If you want to rebase your branch on a specific commit, you can use the following commands:

```bash
git checkout <branch_name>
git rebase <commit>
```
## Fork

If you want to contribute to a project but you can't or don't want to push to the original repo, you can fork the repository.
This means that you create a copy of the repository in your account, and you can push to it.
To fork a repository, go to the repository page, click on the `Fork` button, and select your account.
Then you can clone the forked repository and push to it.


## Git system files

### .gitignore
Sometimes you might want to ignore some files from git, like temporary files or build files.
To do this, you can create a `.gitignore` file in the root of the repository.
In this file, you can list the files or directories you want to ignore.
For example, to ignore all `.png` files, you can add the following line to the `.gitignore` file:

```
*.png
```
You can also ignore whole repositories by adding the directory name to the `.gitignore` file.  

### .gitmodules
If you want to include a submodule in your repository, you can create a `.gitmodules` file in the root of the repository.
In this file, you can list the submodules you want to include.
For example, to include a submodule called `my-submodule`, you can add the following lines to the `.gitmodules` file:

```
[submodule "my-submodule"]
    path = my-submodule
    url =
```
You can also include the URL of the submodule in the `.gitmodules` file.
Then, to initialize the submodule you need to run the following command:

```bash
git submodule update --init
```
This repo also contains a script to manage the submodules, you can look there to see more commands.

