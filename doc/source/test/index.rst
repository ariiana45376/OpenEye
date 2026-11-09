.. _test:

Tests and Verification
======================

The launcher ``test/cocotb_PE/run_recorded.sh`` runs selected
Cocotb tests locally and in GitHub Actions. Icarus is the default
simulator. The ``pe_seed42`` case is also checked with Verilator,
including execution in Docker. Each run has its own results directory.

Simulation cases
----------------

.. list-table:: Cases included in the CI workflow
   :header-rows: 1
   :widths: 45 30 25

   * - Case
     - Testbench
     - Seed
   * - ``pe_seed42``
     - PE
     - 42
   * - ``pe_seed43``
     - PE
     - 43
   * - ``pe_simple_seed42``
     - PE_simple
     - 42

Local execution
---------------

From the repository root, activate the environment containing
the simulation dependencies:

.. code-block:: bash

   source .venv/bin/activate
   export PYTHONPATH="$PWD/src${PYTHONPATH:+:$PYTHONPATH}"

Run a case and inspect its exit status:

.. code-block:: bash

   bash test/cocotb_PE/run_recorded.sh pe_seed42
   printf 'Exit status: %s\n' "$?"

The other cases are invoked with:

.. code-block:: bash

   bash test/cocotb_PE/run_recorded.sh pe_seed43
   bash test/cocotb_PE/run_recorded.sh pe_simple_seed42

Run cases sequentially because generated parameter and input
files may be shared.

Verilator simulation
--------------------

Use Cocotb 2.1.0 and Verilator 5.036 or newer. With a compatible
``verilator`` executable on ``PATH``, run:

.. code-block:: bash

   SIM=verilator bash test/cocotb_PE/run_recorded.sh pe_seed42

To select another installation for one run, prefix the command with
``PATH="/path/to/verilator/bin:$PATH"``, using its actual bin directory.
Verilator waveform tracing is disabled by default.

Docker simulation
-----------------

Docker supplies the Python environment and simulators.
With Docker running, build the image from the repository root:

.. code-block:: bash

   docker build --progress=plain -t openeye-sim:verilator-5.036 .

Run ``pe_seed42`` with Verilator inside the container:

.. code-block:: bash

   docker run --rm \
       --user "$(id -u):$(id -g)" \
       --mount "type=bind,source=$PWD,target=/workspace" \
       --env SIM=verilator \
       openeye-sim:verilator-5.036
   printf 'Exit status: %s\n' "$?"

The mounted checkout preserves results in
``test/cocotb_PE/results/`` after the container exits.


Recorded outputs
----------------

Each run prints its unique results directory:

* PE: ``test/cocotb_PE/results/``
* PE_simple: ``test/cocotb_PE_simple/results/``

The recorded outputs include:

* ``metadata.txt``: case, seed, simulator, source revision, tool version,
  working directory, command, local Git status and exit status.
* ``output.log``: build output and simulation summary.
* ``results.xml``: Cocotb test results, when generated.
* ``source.patch``: changes to tracked files relative to the recorded revision.
* ``PE.fst`` or ``PE_simple.fst``: waveforms, when generated.
* ``sim_build/``: simulator build files.

Untracked files are listed in the metadata but their contents are
not included in ``source.patch``.

Check the exit status and Cocotb summary. Failed or interrupted runs
may have incomplete outputs.


GitHub Actions
--------------

Both simulation workflows run on pushes and pull requests:

* ``PE simulation`` (``.github/workflows/pe-simulation.yml``) runs
  the three Icarus cases and saves the ``pe-results`` artifact.
* ``Verilator simulation (Docker)``
  (``.github/workflows/verilator-simulation.yml``) builds the image,
  runs ``pe_seed42`` and saves ``verilator-pe-results``.

The Docker artifact also contains ``container-image.txt``, which
identifies the built image.

Open the repository's Actions tab, select the workflow run, inspect
its steps and download the artifact.

Artifact upload is attempted even after a simulation failure.
A failure before output creation may leave no files to upload.


Extending the framework
-----------------------

Additional PE seeds can be supplied as numeric arguments:

.. code-block:: bash

   bash test/cocotb_PE/run_recorded.sh 44

To include another case in CI:

1. Validate the case locally.
2. Add its launcher command as a simulation step before
   artifact upload in ``pe-simulation.yml``.
3. Ensure its results directory is included in artifact upload.
4. Update the simulation-case table.

The existing artifact paths include additional PE seed runs.

To support another testbench, extend the launcher's case
selection, testbench invocation and output handling.
Add the corresponding CI step and artifact path, then verify
both successful execution and failure reporting.

Recorded lint checks
--------------------

Run lint from the repository root:

.. code-block:: bash

   bash test/lint/run_recorded.sh pe_dense
   bash test/lint/run_recorded.sh parallel

Use ``pe_dense`` for the PE test configuration or ``parallel`` for
``OpenEye_Parallel`` with its default parameters.

Each run saves results in a new folder under ``test/lint/results/``:

* ``output.log``: warnings and errors.
* ``metadata.txt``: configuration, Git revision, tool version and exit status.
* ``source.patch``: local changes to tracked files.

A nonzero exit status means the check failed.

The ``Lint`` workflow runs both profiles and saves the
``lint-pe_dense`` and ``lint-parallel`` artifacts.