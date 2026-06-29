from .breakpoints import BreakpointManager
from .capabilities import default_capabilities
from .event_dispatcher import EventDispatcher
from .execution_controller import ExecutionController
from .launcher import PantherProgramLauncher
from .response_dispatcher import ResponseDispatcher
from .session import DebugSession
from .source_map import PantherSourceMap


class DebugServer:
    def __init__(
        self,
        session=None,
        launcher=None,
        breakpoint_manager=None,
        source_map=None,
        execution=None,
        events=None,
        responses=None,
    ):
        self.session = session or DebugSession()
        self.launcher = launcher or PantherProgramLauncher()
        self.source_map = source_map or PantherSourceMap()
        self.breakpoint_manager = breakpoint_manager or BreakpointManager()
        self.execution = execution or ExecutionController()
        self.events = events or EventDispatcher()
        self.responses = responses or ResponseDispatcher()

    def initialize(self, arguments=None):
        capabilities = self.session.initialize(arguments or {})
        capabilities.update(default_capabilities())
        capabilities.update({
            "supportsConfigurationDoneRequest": True,
            "supportsTerminateRequest": True,
            "supportsHitConditionalBreakpoints": True,
            "supportsConditionalBreakpoints": True,
            "supportsLogPoints": True,
            "supportsSingleThreadExecutionRequests": True,
        })
        return self.responses.success("initialize", body=capabilities)

    def configuration_done(self):
        self.session.configuration_done()
        return self.responses.success("configurationDone")

    def set_breakpoints(self, arguments):
        arguments = arguments or {}
        source = arguments.get("source") or {}
        source_path = source.get("path") if isinstance(source, dict) else source
        raw_breakpoints = arguments.get("breakpoints", [])
        source_modified = bool(arguments.get("sourceModified", False))

        if not source_path:
            return self.responses.error(
                "setBreakpoints",
                message="setBreakpoints requires source.path",
                body={"breakpoints": []},
            )

        try:
            self.source_map.register_file(source_path, require_exists=False)
        except Exception:
            pass

        adjusted = []
        for raw in raw_breakpoints:
            requested_line = raw.get("line") if isinstance(raw, dict) else raw
            item = dict(raw) if isinstance(raw, dict) else {"line": requested_line}
            try:
                resolved_line, verified, message = self.source_map.resolve_breakpoint_line(
                    source_path,
                    requested_line,
                    require_exists=False,
                )
                item["line"] = resolved_line
                item["_verified"] = verified
                item["_message"] = message
            except Exception as exc:
                item["_verified"] = False
                item["_message"] = str(exc)
            adjusted.append(item)

        breakpoints = self.breakpoint_manager.set_breakpoints(source_path, adjusted, require_exists=False)
        for breakpoint, item in zip(breakpoints, adjusted):
            if "_verified" in item:
                breakpoint.verified = bool(item["_verified"])
            if item.get("_message"):
                breakpoint.message = item["_message"]

        return self.responses.success(
            "setBreakpoints",
            body={
                "breakpoints": [bp.to_dap() for bp in breakpoints],
                "sourceModified": source_modified,
            },
        )

    def launch(self, arguments):
        arguments = arguments or {}
        program = arguments.get("program") if isinstance(arguments, dict) else arguments
        args = arguments.get("args", []) if isinstance(arguments, dict) else []
        cwd = arguments.get("cwd") if isinstance(arguments, dict) else None
        dry_run = arguments.get("dryRun", True) if isinstance(arguments, dict) else True

        launch_info = self.launcher.launch(program, args=args, cwd=cwd, dry_run=dry_run)
        session_info = self.session.launch(program, args=args, cwd=cwd)
        self.execution.prepare(program=program, current_line=1)

        return self.events.process(
            name=program,
            pid=launch_info.pid,
            command=launch_info.command,
            state=session_info["state"],
            execution=self.execution.to_body(),
        )

    def continue_execution(self, arguments=None):
        snapshot = self.execution.continue_execution()
        return self.events.continued(
            thread_id=snapshot.thread_id,
            status=snapshot.status,
            reason=snapshot.reason,
        )

    def pause(self, arguments=None):
        snapshot = self.execution.pause(reason="pause")
        return self.events.stopped(
            "pause",
            thread_id=snapshot.thread_id,
            status=snapshot.status,
            source_command="pause",
        )

    def stop(self, arguments=None):
        snapshot = self.execution.stop(reason="stop")
        return self.events.stopped(
            "stop",
            thread_id=snapshot.thread_id,
            status=snapshot.status,
            source_command="stop",
        )

    def terminate(self):
        self.execution.terminate()
        self.session.terminate()
        return self.events.terminated()

    def disconnect(self):
        self.session.disconnect()
        return self.events.exited(exit_code=0)
