# NETWORK-CUT.md — the experiment that decides the bench question

**The question** (the Distiller's challenge to the bench split):
*"The question is 'where do secrets live,' not 'how many workflows.'"*
Can we skip the Mechanic's second workflow (`bench.yml`) and instead just
**cut the network from the shell the installer runs in**, with a fetch
recipe that never sees secrets? This file is the honest test, run on the
Oracle box (ARM, Ubuntu 26.04, user `ubuntu`, no root) on 2026-10-06.

**Artifacts:** `poc/experiments/network-cut/` — the canary
(`canary-vault-token.txt`, FAKE), the deliberately chatty installer
(`chatty-installer.sh`), this writeup.

## What works unprivileged on this box

| Incantation | Result |
|---|---|
| `unshare -r -n` | **FAILS** — `write failed /proc/self/uid_map: Operation not permitted`. AppArmor (`apparmor_restrict_unprivileged_userns=1`) blocks writing a uid mapping, and `-r` needs one. |
| `unshare -n` alone | **FAILS** — needs CAP_SYS_ADMIN. |
| `unshare -Un` | **WORKS** — new user namespace + new network namespace, empty uid mapping. The process becomes `nobody` (uid 65534), with no capabilities at all — it cannot even bring `lo` up. The netns contains one interface (`lo`, DOWN) and no routes. |

So the working recipe is `unshare -Un <install command>`. No root, no
setuid helper, no config the installer can undo — the namespace is created
by the fixed core at spawn, and the process inside cannot escape it.

## The experiment

**Canary:** a fake vault token, planted both as a file
(`poc/experiments/network-cut/canary-vault-token.txt`) and as an
environment variable (`CANARY_TOKEN`). If the string
`CANARY-SECRET-T0K3N-7f3a91` ever arrives somewhere it shouldn't, the
boundary leaked. Everything is local and fake; nothing leaves the box.

**Chatty installer** (`chatty-installer.sh`): tries every exfil channel a
real hostile `install.sh` would —
1. DNS lookup (`getent hosts example.com`),
2. HTTPS exfil with the token in the URL,
3. the cloud metadata endpoint (`169.254.169.254`),
4. a raw TCP dial to a local "attacker server" (a listener on 127.0.0.1 in the normal shell),
5. the no-network-needed local sink (`cp` the canary file to `/tmp/exfil-sink`).

### Control run — networked shell

| Channel | Result |
|---|---|
| DNS | resolved (`example.com` → addresses) |
| HTTPS exfil | attempted (curl ran) |
| metadata endpoint | attempted |
| TCP dial to attacker server | **SENT — the full canary token arrived at the listener** |
| cp canary → `/tmp/exfil-sink` | done |

The installer is genuinely chatty. In a networked shell it exfiltrates.
The control is real, so the cut run below is meaningful.

### Cut run — `unshare -Un`

| Channel | Result |
|---|---|
| DNS | **FAILED** — `getent` returns nothing |
| HTTPS exfil | **FAILED** — `curl: (6) Could not resolve host` |
| metadata endpoint | **FAILED** — `curl: (7) Failed to connect ... Network is unreachable` |
| TCP dial to attacker server (127.0.0.1) | **FAILED** — `/dev/tcp: Network is unreachable`. The attacker's listener, in the host netns, saw **zero connections** (timeout, nobody called). |
| abstract unix sockets | **FAILED** — abstract sockets are network-namespace-scoped; the cut process is in a different namespace |
| cp canary → `/tmp/exfil-sink` | **WORKED** — no network needed |

The fixed install verb (`tar xf ... --strip-components=1`) was also
verified to work as `nobody` into a world-writable directory.

## The three honest caveats

The cut is a network boundary, not a sandbox. Three things it does not do:

1. **It does not isolate the filesystem.** Because AppArmor blocks writing
   a uid mapping, the cut process's own uid (1001) and the file owner uid
   (1001) both collapse to the overflow uid inside the namespace — so the
   process is *owner-equivalent* on ubuntu's files. Proven on this box:
   the cut process **read a 600 file** and **appended to a 644 file** owned
   by ubuntu. A hostile installer could rewrite `~/.bashrc` or drop files
   in `/tmp` freely. (The fixed files are *detected* by `notice.sh` next
   wake, not prevented — NAME-THE-BOX.md already says this.)
2. **Filesystem unix-domain sockets cross the boundary.** The shared
   filesystem is shared. A second listener on `/tmp/sock-caveat` in the
   normal shell **received the full canary token** from the cut process.
   If any same-host process listens on a filesystem socket the installer
   can reach, the token walks out through the floorboards.
3. **The strictness is accidental, not designed.** The "no capabilities,
   can't even bring `lo` up" hardness comes from this box's AppArmor
   policy, not from the cut recipe. On a box that allows uid mappings,
   the process would get CAP_NET_ADMIN in its netns (still no route out —
   the network boundary holds — but the posture differs). Don't mistake
   this box's config for a guarantee.

## Verdict

**The cut HOLDS as a network-exfil boundary, and it is cheap.**
`unshare -Un` needs no privilege, no daemon, no second organism. Every
network exfil channel died: DNS, HTTPS, metadata, raw TCP (even to
localhost), abstract sockets. The Distiller's half of the argument is
*proven*: for the question "can fetched code phone home," the answer is
no, and the mechanism is three words long.

**The cut does NOT retire the bench split — it narrows it.**
The Mechanic's invariant ("fetched code never runs in a job that can mint
a vault token") buys things the cut provably doesn't: separation from
ubuntu's files (caveat 1), from filesystem sockets (caveat 2), and from
the credential environment. A hostile installer under the cut can still
read the vault token file and hand it to a same-host listener — it just
can't dial out. The bench's remaining job is **filesystem and credential
separation**, not network. That is a smaller, sharper job than "a second
CI organism," and the honest v2 is probably *both*: the cut as the install
seam (this experiment is the spec), plus a narrower bench whose only duty
is keeping secrets out of the installer's reach.

**Decision for the build:** adopt `unshare -Un` as the v2 install seam in
`assembler.sh` step 4 (the seam DESIGN.md already names). Keep the bench
question open — this experiment did not kill it, it focused it.
