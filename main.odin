// when you want to pause a function, do some other stuff, and 
// finish your unfinished business...
package memrepo

import "core:c/libc"
import "core:container/queue"
import "core:fmt"
import "core:time"


Repo :: struct {
	storage: map[i64]libc.jmp_buf,
	// where to start
	anchor:  libc.jmp_buf,
	// what is deleted
	queue:   queue.Queue(i64),
	// garbage collection
	cleanup: [dynamic]i64,
}

cleanup :: proc(r: ^Repo) {
	for item in r.cleanup {
		delete_key(&r.storage, item)
	}
	clear(&r.cleanup)
}

cleanup_pause :: proc(r: ^Repo) {
	cleanup(r)
}

@(deferred_in = cleanup_pause)
pause :: #force_inline proc(r: ^Repo) {
	rn := time.tick_now()
	r.storage[rn._nsec] = libc.jmp_buf{}
	if libc.setjmp(&r.storage[rn._nsec]) == 1 {
		return
	}
	queue.push_back(&r.queue, rn._nsec)
	libc.longjmp(&r.anchor, 1)
}

cleanup_resume :: proc(r: ^Repo, _: i64) {
	cleanup(r)
}

@(deferred_in = cleanup_resume)
resume :: proc(r: ^Repo, time: i64) -> bool {
	buf, ok := r.storage[time]
	if !ok {
		return false
	}
	// mark to be garbage collected
	append(&r.cleanup, time)
	libc.longjmp(&buf, 1)
}

make_repo :: proc() -> Repo {
	rew := Repo{}
	queue.init(&rew.queue, capacity = 2048)
	return rew
}

anchor_jump :: #force_inline proc(rew: ^Repo) {
	libc.longjmp(&rew.anchor, 1)
}

anchor :: #force_inline proc(rew: ^Repo) {
	libc.setjmp(&rew.anchor)
}

get_paused :: proc(rew: ^Repo) -> (timestamp: i64, ok: bool) {
	timestamp, ok = queue.pop_front_safe(&rew.queue)
	return
}
