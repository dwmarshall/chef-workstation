# Copyright:: Copyright (c) 2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef-cli/telemetry"
require "chef-cli/config"

RSpec.describe ChefCLI::Telemetry::Sender do
  let(:subject) { ChefCLI::Telemetry::Sender.new }
  describe "#run" do
    let(:session_files) { %w{file1 file2} }
    it "submits the session capture for each session file found" do
      expect(subject).to receive(:session_files).and_return session_files
      expect(subject).to receive(:process_session).with("file1")
      expect(subject).to receive(:process_session).with("file2")
      subject.run
    end

  end

  describe "#session_files" do
    it "finds all telemetry-payload-*.yml files in the telemetry directory" do
      expect(ChefCLI::Config).to receive(:telemetry_path).and_return("/tmp")
      expect(Dir).to receive(:glob).with("/tmp/telemetry-payload-*.yml").and_return []
      subject.session_files
    end
  end

  describe "process_session" do
    it "loads the sesion and submits it" do
      expect(subject).to receive(:load_and_clear_session).with("file1").and_return({ "entries" => [] })
      expect(subject).to receive(:submit_session).with({ "entries" => [] })
      subject.process_session("file1")
    end
  end

  describe "submit_session" do
    let(:telemetry) { instance_double("telemetry") }
    it "removes the telemetry session file and starts a new session, then submits each entry in the session" do
      expect(ChefCLI::Config).to receive(:telemetry_session_file).and_return("/tmp/SESSION_ID")
      expect(FileUtils).to receive(:rm_rf).with("/tmp/SESSION_ID")
      expect(::Telemetry).to receive(:new).and_return telemetry
      expect(subject).to receive(:submit_entry).with(telemetry, { "event" => "action1" }, 1, 2)
      expect(subject).to receive(:submit_entry).with(telemetry, { "event" => "action2" }, 2, 2)
      subject.submit_session( { "entries" => [ { "event" => "action1" }, { "event" => "action2" } ] } )
    end
  end

  describe "submit_entry" do
    let(:telemetry) { instance_double("telemetry") }
    it "submits the entry to telemetry" do
      expect(telemetry).to receive(:deliver).with("test" => "this")
      subject.submit_entry(telemetry, { "test" => "this" }, 1, 1)
    end
  end

end
