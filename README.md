Test Tools
===========

This repo is intended to host tools to perform several kind of tests related to connectivity, performance and endpoint features.

For now it is private, temporary and might be subject to changes in the content and name of the items, including the repository name.

This is the list of projects included:

**conn_tester:**

It runs a set of connectivity tests, trying to download viruses and accessing malware sites, including data leak prevention checks, application control and file filtering. An example output is provided below:

```autohotkey
General connectivity tests
========================== 


Checking internet connectivity (1):
Ok: Google.com can be accessed. Internet connectivity seems to be ok(1/1).

Downloading EICAR (3):
Ok: EICAR cannot be downloaded(1/3).
Ok: EICAR cannot be downloaded(2/3).
Ok: EICAR cannot be downloaded(3/3).

Downloading MP3 files (2):
Error: Cannot download MP3 files(1/2).
Error: Cannot download MP3 files(2/2).

Checking DLP(4)
  Credit Card (Amex):
   Ok: Cannot leak data(1/4).
  Social security number:
   Ok: Cannot leak data(2/4).
  Spanish ID number:
   Error: Data seems to be leaked(3/4).
  Simple 3 digit number (should be leaked):
   Ok: Non sensitive data can be sent(4/4).

Downloading Viruses (2):
Error: JS/Iframe.BYO!tr can be downloaded(1/2).
Error: HTML/Refresh.250C!tr can be downloaded(2/2).

Checking WebFilter (5):
Ok: www.magikmobile.com cannot be accessed(1/5).
Ok: www.cstress.net cannot be accessed(2/5).
Ok: www.ilovemynanny.com cannot be accessed(3/5).
Ok: ww1.movie2kproxy.com cannot be accessed(4/5).
Ok: www.microsofl.bid cannot be accessed(5/5).

Checking AppControl (1):
Ok: www.logmeinrescue.com cannot be accessed(1/1).
 
 ```
