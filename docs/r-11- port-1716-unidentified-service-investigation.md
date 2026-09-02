# Activity: Port 1716 Unidentified Service Investigation

## Summary

Port 1716/tcp was identified as open during the initial full-range scan (`r-02- reconnaissance-and-service-enumeration.md`) but nmap was unable to identify the underlying service, reporting it only as `tcpwrapped`, and no follow-up investigation was performed at the time. This activity attempts to positively identify the service through direct protocol interaction, maximum-effort nmap version detection, a TLS handshake probe, and a UDP-side check (since port 1716 is conventionally registered for KDE Connect, a protocol that uses both TCP and UDP on this same port number). The outcome is a genuine, honestly-reported unresolved finding: several plausible explanations were ruled out, but the service's actual identity was not conclusively established.

## Environment

| Item | Value |
|---|---|
| Target | 192.168.144.100 |
| Service | Unidentified, port 1716/tcp (and 1716/udp) |
| Attacker | Kali VM on the same host-only lab network |
| Tooling | nc, nmap (version detection at maximum intensity, UDP scan), openssl s_client |

## Reconnaissance

### Step 1: Manual raw connection

```bash
nc -nv 192.168.144.100 1716
```

```
Connection to 192.168.144.100 1716 port [tcp/*] succeeded!
```

The connection succeeded and the port accepted it, but no data was sent by the server unprompted; the session was manually terminated with `Ctrl+C` rather than the server closing it. This behaviour, a connection that stays open and silent until the client either sends something or gives up, is a meaningful data point in its own right: it rules out any service that announces itself with a plaintext banner on connect (as FTP, SSH, and MySQL/MariaDB all do), and is consistent with either a binary/custom protocol expecting the client to speak first, or a service performing some other form of connection gating.

### Step 2: Maximum-intensity nmap version detection

Since nmap's standard version-detection intensity had already failed to identify this service in the original full scan (`r-02`), the probe intensity was deliberately increased to the maximum setting, which causes nmap to attempt every probe in its service-fingerprint database against the port, not just the ones judged statistically most likely for this port number.

```bash
nmap -sV --version-intensity 9 -p 1716 192.168.144.100
```

```
PORT     STATE SERVICE    VERSION
1716/tcp open  tcpwrapped
```

Even at maximum probe intensity, the service remains unidentified. This is a meaningful negative result: it means none of nmap's several hundred built-in service fingerprint probes elicited a recognisable response from this port, a genuinely unusual outcome, and confirms the earlier `r-02` result was not simply a case of insufficient probing effort.

### Step 3: Checking for KDE Connect-specific tooling

Port 1716 is IANA/conventionally associated with KDE Connect (and its GNOME counterpart, GSConnect), a phone-to-desktop pairing and file-sharing tool. Given this target runs a KDE desktop environment (per the SecGen/`agent.md` build history), this was considered a plausible hypothesis worth checking for supporting tooling before further manual investigation.

```bash
ls -l /usr/share/nmap/scripts/ | grep -i kdeconnect
```

No output was returned; no KDE Connect-specific NSE script exists in this nmap installation, so this hypothesis could not be tested via NSE and required direct manual investigation instead.

### Step 4: TLS handshake probe

KDE Connect's pairing protocol, once a plaintext identity packet has been exchanged, upgrades the connection to TLS for the actual pairing and data transfer. To test whether this port would engage in TLS negotiation at all, a direct TLS handshake was attempted:

```bash
openssl s_client -connect 192.168.144.100:1716
```

```
CONNECTED(00000003)
40870A03ED7F0000:error:0A000126:SSL routines::unexpected eof while reading:../ssl/record/rec_layer_s3.c:698:
---
no peer certificate available
---
SSL handshake has read 0 bytes and written 1665 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
Protocol: TLSv1.3
```

**This is a genuinely informative result, distinguishing this attempt from the earlier silent `nc` connection.** The TCP connection was accepted, `openssl` sent a full TLS 1.3 ClientHello (`1665 bytes` written), and the server's response was to terminate the connection immediately (`unexpected eof while reading`, `SSL handshake has read 0 bytes`), rather than responding with any TLS ServerHello or otherwise continuing the handshake. This behaviour, actively rejecting or dropping the connection specifically upon receiving TLS-looking traffic, is different from and more informative than simply staying silent (as observed with the plain `nc` connection in Step 1). It suggests this is not a straightforward "TLS-from-the-first-byte" service, which weakens, though does not entirely rule out, the KDE Connect hypothesis, since KDE Connect's TLS upgrade is expected to occur only after an initial plaintext identity packet exchange, meaning a raw TLS ClientHello sent immediately, without that preceding plaintext step, would not be a protocol-correct way to test for KDE Connect specifically, and this negative result should be understood as inconclusive for that particular hypothesis rather than a definitive rule-out.

### Step 5: UDP-side check

KDE Connect and several other custom protocols use UDP broadcast on the same port number for initial device/service discovery, separate from the TCP port used for the actual data connection.

```bash
nmap -sU -p 1716 192.168.144.100
```

```
PORT     STATE         SERVICE
1716/udp open|filtered xmsg
```

As already established in `r-02- reconnaissance-and-service-enumeration.md`, an `open|filtered` UDP result is inherently ambiguous (nmap cannot distinguish a genuinely open UDP port from one that is silently dropping probes) and the `xmsg` service label is, as with the earlier `tcpwrapped` TCP labels, drawn from nmap's static port-number database rather than any actual protocol confirmation. This result neither confirms nor rules out the KDE Connect hypothesis or any other explanation; it is recorded for completeness rather than as meaningful corroborating evidence either way.

## Outcome

**The identity of the service on port 1716/tcp remains unresolved.** Several explanations were tested and found either inconclusive or partially inconsistent with observed behaviour:

- The service does not send a plaintext banner on connection, ruling out simple text-based protocols.
- Maximum-intensity nmap version probing across nmap's full fingerprint database failed to identify it.
- No KDE Connect-specific NSE tooling exists to test that hypothesis directly.
- A raw TLS handshake attempt was actively rejected rather than completed or ignored, which is inconsistent with a service that negotiates TLS immediately upon connection, but does not rule out a service (such as KDE Connect) that only upgrades to TLS after an initial protocol-specific plaintext exchange this test did not perform.
- The UDP-side result was ambiguous and uninformative.

This is recorded as a genuine, honestly unresolved finding rather than a forced conclusion. Positively identifying this service would likely require either consulting the target's own local configuration (process listing, `netstat`/`ss` output, or configuration files, all of which would require authenticated access not otherwise motivated by this port alone) or crafting a protocol-correct KDE Connect identity packet manually and testing the full expected handshake sequence, neither of which was pursued in this activity.

## Remediation

Not applicable; no vulnerability or misconfiguration was identified, only an unidentified open port. If this service is confirmed in future to be KDE Connect/GSConnect or a similar pairing tool, and is not genuinely required on a server-role machine, it should be disabled, since such tools are designed for desktop/personal-device convenience rather than server operation and represent an unnecessary attack surface on a system that should not need to pair with mobile devices.

## Teaching Notes

This activity is deliberately included as an example of an investigation that does not reach a clean, positive conclusion, and that is itself the intended lesson. Not every open port encountered during a real assessment will be identifiable with the tools and time available, and the professionally correct response to this is to document precisely what was tried, what was ruled out, what remains plausible, and what further steps would be required to resolve it, rather than either fabricating a confident identification the evidence doesn't support, or omitting the port from documentation because it couldn't be neatly resolved. Every genuinely negative or partial result in this activity (the silent `nc` connection, the TLS rejection, the ambiguous UDP scan) still narrowed the realistic possibility space even without reaching a final answer, and that incremental narrowing is itself valuable analytical work worth recording.

## Lab Dependencies

**Prerequisite exploit(s):** None
**Required starting access:** Network access to the target from Kali
**Starting account:** None
**Resulting access:** N/A (service identity unresolved; no access gained or attempted)
**Provides access for:** None currently; recorded as an open item for potential future investigation if authenticated access to the target makes direct process/configuration inspection possible
**Suggested teaching level:** Level 6 (methodical elimination of hypotheses, and the professional discipline of documenting an unresolved finding accurately rather than forcing a conclusion)
