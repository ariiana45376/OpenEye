.. _test:

Tests and Verification
======================

The simulation framework runs OpenEye Cocotb testbenches with
Icarus Verilog. The launcher
``test/cocotb_PE/run_recorded.sh`` provides a shared entry point
for local execution and GitHub Actions, recording each run in
a separate results directory.

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

Recorded outputs
----------------

The launcher prints the results directory for each run.
Results are stored under:

* PE: ``test/cocotb_PE/results/``
* PE_simple: ``test/cocotb_PE_simple/results/``

The recorded outputs include:

* ``metadata.txt``: case, seed, working directory, command
  and exit status.
* ``output.log``: build output and simulation summary.
* ``results.xml``: Cocotb test results, when generated.
* ``PE.fst`` or ``PE_simple.fst``: waveforms, when generated.
* ``sim_build/``: simulator build files.

Check the exit status and the Cocotb summary when assessing
a run. Failed or interrupted runs may have incomplete outputs.

For reproducibility, record the tested Git commit, local
modifications and tool versions alongside the results.

GitHub Actions
--------------

The workflow is defined in
``.github/workflows/pe-simulation.yml`` and runs on pushes
and pull requests.

To inspect a run:

1. Open the repository's Actions tab.
2. Select a ``PE simulation`` run.
3. Inspect the individual simulation steps.
4. Download the ``pe-results`` artifact for the recorded outputs.

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