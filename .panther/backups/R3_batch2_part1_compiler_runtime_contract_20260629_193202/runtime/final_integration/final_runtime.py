from dataclasses import dataclass, field

from runtime.ai_runtime.ai_runtime import PantherAIRuntime
from runtime.task_scheduler.scheduler import Scheduler
from runtime.multi_agent.bus import AgentBus, Agent
from runtime.context_state.state_engine import ContextEngine
from runtime.plugins.plugin_system import PluginManager
from runtime.sandbox.sandbox import SandboxRuntime
from runtime.distributed.distributed_runtime import DistributedRuntime


@dataclass
class FinalRuntimeReport:
    ok: bool
    phase: str
    runtime_started: bool
    scheduler_tasks: int
    messages: int
    context_ok: bool
    plugins: int
    sandbox_ok: bool
    distributed_nodes: int


class PantherFinalRuntime:
    def __init__(self):
        self.ai_runtime = PantherAIRuntime()
        self.scheduler = Scheduler()
        self.bus = AgentBus()
        self.context = ContextEngine()
        self.plugins = PluginManager()
        self.sandbox = SandboxRuntime()
        self.distributed = DistributedRuntime()

    def run_full_integration(self) -> FinalRuntimeReport:
        self.ai_runtime.initialize()
        exec_result = self.ai_runtime.execute("phase7.10.integration")

        self.scheduler.add("agent-task", "execute")
        scheduled = self.scheduler.run()

        research = Agent("research", self.bus)
        report = Agent("report", self.bus)
        research.send("report", "analysis complete")
        inbox = self.bus.inbox("report")

        self.context.global_state.set("mission", "phase7-final")
        self.context.sync("research", "mission")
        context_ok = self.context.context("research").get("mission") == "phase7-final"

        self.plugins.register("security")
        self.plugins.register("ai")

        sandbox_result = self.sandbox.execute("agent.run")

        self.distributed.register("node-a")
        self.distributed.register("node-b")
        broadcast = self.distributed.broadcast("sync")

        self.ai_runtime.shutdown()

        return FinalRuntimeReport(
            ok=(
                exec_result["ok"]
                and len(scheduled) == 1
                and len(inbox) == 1
                and context_ok
                and len(self.plugins.list()) == 2
                and sandbox_result["sandbox"] == "secure"
                and len(broadcast) == 2
            ),
            phase="7.10",
            runtime_started=False,
            scheduler_tasks=len(scheduled),
            messages=len(inbox),
            context_ok=context_ok,
            plugins=len(self.plugins.list()),
            sandbox_ok=sandbox_result["sandbox"] == "secure",
            distributed_nodes=self.distributed.node_count(),
        )
