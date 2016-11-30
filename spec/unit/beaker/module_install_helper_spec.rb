require 'spec_helper'

describe 'ModuleInstallHelper' do
  context 'install_module_on' do
    it 'raises not implemented error' do
      expect { install_module_on(nil) }.to raise_error /Not Implemented Yet/
    end
  end
end
