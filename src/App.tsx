/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export default function App() {
  return (
    <div className="min-h-screen bg-neutral-900 text-neutral-100 p-8 font-sans">
      <div className="max-w-3xl mx-auto space-y-8">
        <header className="space-y-2 border-b border-neutral-800 pb-8">
          <h1 className="text-4xl font-bold tracking-tight text-white">Dart AI Chat CLI</h1>
          <p className="text-xl text-neutral-400 italic">"Pure Dart, AI-First, Command-Line Powered."</p>
        </header>

        <section className="bg-neutral-800/50 p-6 rounded-xl border border-neutral-700/50">
          <h2 className="text-2xl font-semibold mb-4 text-emerald-400">Project Status</h2>
          <p className="mb-4">
            The core architecture, server-client logic, and AI personalities have been implemented in the <code>/bin</code> and <code>/lib</code> directories using Dart.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-black/30 rounded-lg">
              <h3 className="font-mono text-sm uppercase text-neutral-500 mb-2">Components</h3>
              <ul className="list-disc list-inside text-sm space-y-1">
                <li>TCP Server (dart:io)</li>
                <li>CLI Client (stdin/stdout)</li>
                <li>Gemini AI Bridge</li>
                <li>Soft Shutdown Logic</li>
              </ul>
            </div>
            <div className="p-4 bg-black/30 rounded-lg">
              <h3 className="font-mono text-sm uppercase text-neutral-500 mb-2">Personalities</h3>
              <ul className="list-disc list-inside text-sm space-y-1">
                <li>Cynical Carl (Critic)</li>
                <li>Professor Spark (Polymath)</li>
                <li>Luna Vane (Poet)</li>
              </ul>
            </div>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">How to interact</h2>
          <p className="text-neutral-400">
            As this is a CLI application, please refer to the <code>README.md</code> for local execution instructions.
            Detailed planning materials can be found in the <code>/plan</code> directory.
          </p>
          <div className="bg-neutral-950 p-4 rounded-lg font-mono text-sm border border-neutral-800">
            <div className="flex items-center gap-2 mb-2 text-emerald-500">
              <div className="w-2 h-2 rounded-full bg-emerald-500" />
              <span>Available Commands</span>
            </div>
            <div className="text-neutral-500">
              $ /ai_join [id] - Spawn an AI personality<br />
              $ /ai_join ?    - Generate a Mystery Guest!<br />
              $ /exit         - Graceful exit<br />
            </div>
          </div>
        </section>

        <footer className="text-neutral-500 text-xs text-center border-t border-neutral-800 pt-8">
          Designed by Senior AI Engineering Agent • Standard Library Only
        </footer>
      </div>
    </div>
  );
}
