module TildeConfig
  RSpec.describe 'The install command line function' do
    it 'should return true by default' do
      expect(TildeConfigSpec.suppress_output do
        CLI.run(%w[install], load_config_file: false)
      end)
        .to be_truthy
    end

    it 'should run install actions' do
      install1_called = false
      install2_called = false
      install3_called = false
      TildeConfigSpec.run(%w[install]) do
        mod :mod1 do |m|
          m.install do
            install1_called = true
          end
        end

        mod :mod2 do |m|
          m.install do
            install2_called = true
          end
          m.install do
            install3_called = true
          end
        end
      end

      expect(install1_called).to be_truthy
      expect(install2_called).to be_truthy
      expect(install3_called).to be_truthy
    end

    it 'should only install the specified modules' do
      install1_called = false
      install2_called = false
      install3_called = false
      TildeConfigSpec.run(%w[install mod1 mod3]) do
        mod :mod1 do |m|
          m.install do
            install1_called = true
          end
        end

        mod :mod2 do |m|
          m.install do
            install2_called = true
          end
        end

        mod :mod3 do |m|
          m.install do
            install3_called = true
          end
        end
      end

      expect(install1_called).to be_truthy
      expect(install2_called).to be_falsey
      expect(install3_called).to be_truthy
    end

    it 'should detect unknown modules' do
      result = TildeConfigSpec.run(%w[install fake_mod], should_succeed: false)
      expect(result).to be_falsey
    end

    it 'should install modules in the correct order' do
      installed = []
      TildeConfigSpec.run(%w[install]) do
        mod :mod1 => [:mod2, :mod3] do |m|
          m.install do
            installed << :mod1
          end
        end

        mod :mod2 do |m|
          m.install do
            installed << :mod2
          end
        end

        mod :mod3 => [:mod2] do |m|
          m.install do
            installed << :mod3
          end
        end
      end
      expect(installed).to eq([:mod2, :mod3, :mod1])
    end

    it 'should install dependent modules' do
      installed = []
      TildeConfigSpec.run(%w[install mod1]) do
        mod :mod1 => [:mod2, :mod3] do |m|
          m.install do
            installed << :mod1
          end
        end

        mod :mod2 do |m|
          m.install do
            installed << :mod2
          end
        end

        mod :mod3 => [:mod2] do |m|
          m.install do
            installed << :mod3
          end
        end
      end
      expect(installed).to eq([:mod2, :mod3, :mod1])
    end

    it 'should stop when an action fails by default' do
      flag = false
      TildeConfigSpec.run(%w[install mod1], should_succeed: false) do
        mod :mod1 do |m|
          m.install do
            raise ActionError, ''
          end
          m.install do
            flag = true
          end
        end
      end

      expect(flag).to be_falsey
    end

    it 'should execute all actions if --ignore-errors passed' do
      flag = false
      TildeConfigSpec.run(%w[install mod1 --ignore-errors]) do
        mod :mod1 do |m|
          m.install do
            raise ActionError, ''
          end
          m.install do
            flag = true
          end
        end
      end

      expect(flag).to be_truthy
    end
  end
end
