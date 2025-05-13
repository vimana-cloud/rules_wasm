diff --git wasm.bzl wasm.bzl
new file mode 100644
index 0000000..f81ea70
--- /dev/null
+++ wasm.bzl
@@ -0,0 +1,27 @@
+# TODO: Figure out how to dedupe this with `wasm.bzl`.
+wasi_packages = {
+    "cli": [
+        "clocks",
+        "filesystem",
+        "io",
+        "random",
+        "sockets",
+    ],
+    "clocks": ["io"],
+    "filesystem": [
+        "clocks",
+        "io",
+    ],
+    "http": [
+        "cli",
+        "clocks",
+        "io",
+        "random",
+    ],
+    "io": [],
+    "random": [],
+    "sockets": [
+        "clocks",
+        "io",
+    ],
+}
