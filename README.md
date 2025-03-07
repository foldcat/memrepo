# memrepo

pause the execution of a function, go back to a point, do some other stuff, resume the function

# example
```odin
// force inline is a MUST
testfn :: #force_inline proc(rew: ^Repo) {
	fmt.println("pausing")
	pause(rew)
	fmt.println("unpaused")
}

main :: proc() {
	rew := make_repo()
	anchor(&rew)
	fmt.println("anchored")

	if item, ok := get_paused(&rew); ok {
		fmt.println("pre resume")
		resume(&rew, item)
	} else {
		fmt.println("running testfn")
		testfn(&rew)
	}

	fmt.println("done with it")
}

/*
output:
anchored
running testfn
pausing
anchored 
pre resume
unpaused
done with it
*/
```
