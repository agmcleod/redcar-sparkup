module Redcar

    class Sparkup

        def self.plugin_dir
          File.join(File.dirname(__FILE__), "..")
        end
        
        attr_accessor :indent_spaces

        # Default sparkup command, if OS has Python
        @@sparkup_cmd = ""

        def initialize
          self.indent_spaces = self.class.get_indent_value
          @@sparkup_cmd = "#{Sparkup.plugin_dir}/assets/sparkup/sparkup --indent-spaces=#{self.indent_spaces}"
          
          # Set the menu item
          self.class.menus

          # Set the keybindings
          # TODO: Make the keybindings as a preference
          self.class.keymaps

          # Jython fallback if Python isn't installed
          unless self.class.hasPython
              @@sparkup_cmd = "java -jar #{Sparkup.plugin_dir}/jython/jython.jar #{Sparkup.plugin_dir}/assets/sparkup/sparkup --indent-spaces=#{self.indent_spaces}"
          end
        end
        
        def self.get_indent_value
          path = File.join(Redcar.user_dir, 'storage/sparkup.yaml')
          begin
            contents = IO.read(path)
          rescue Errno::ENOENT
            self.create_default_file
          end
          indent_spaces = contents.split(':')[1].gsub(/\n/,'').to_i
          indent_spaces = 4 if indent_spaces < 1 || indent_spaces.nil?
          indent_spaces
        end
        
        def self.set_new_value(value)
          File.open(File.join(Redcar.user_dir, 'storage/sparkup.yaml'), 'w+') do |f|
            f.write("indent_spaces:#{value}")
          end
        end

        # Get Sparkup's cmd
        def getCmd
          @@sparkup_cmd
        end
        
        def self.create_default_file
          self.set_new_value(4)
          4
        end
        
        # def create_default_file
        #  self.indent_spaces = self.class.create_default_file
        # end

        # Shows the menu in the toolbar
        def self.menus
            Redcar::Menu::Builder.build do
                sub_menu "Plugins" do
                    sub_menu "Sparkup" do
                        item "Sparkup line", SparkupLine
                        item "Edit Sparkup", EditSparkup
                        item "Set Indent Level", SetIndentLevel
                    end
                end
            end
        end

        # Makes the keybindings
        def self.keymaps
            map = Redcar::Keymap.build("main", [:osx, :linux, :windows]) do
                link "Ctrl+Shift+D", SparkupLine
                link "Ctrl+Shift+I", SetIndentLevel
            end
            [map]
        end

        # Check if Python is installed
        def self.hasPython

            if Redcar.platform == :windows

                # I haven't found a useable python test
                # Got any? Send them to me pls
                return false
            else

                pTest = `which python`
                return pTest != ''
            end
        end
        
        class IndentLevelSpeedBar < Speedbar
          label :indent_spaces_label, "Indent Spaces:"
          textbox :indent_spaces do |value|
            Sparkup.set_new_value(value)
            indent_spaces.value = value
          end
          
          def after_draw
            self.indent_spaces.value = Sparkup.get_indent_value.to_s
          end
        end

        # Open Sparkup's file (this) for edit
        class EditSparkup < Redcar::Command
            def execute

                Project::Manager.open_project_for_path(
                    File.join(File.dirname(__FILE__), "..")
                )

                tab = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
                mirror = Project::FileMirror.new(File.join(
                    File.join(Sparkup.plugin_dir, "lib", "sparkup.rb")
                ))
                tab.edit_view.document.mirror = mirror
                tab.edit_view.reset_undo
                tab.focus
            end
        end
        
        class SetIndentLevel < Redcar::Command
          def execute
            @speedbar = IndentLevelSpeedBar.new(tab)
            win.open_speedbar(@speedbar)
          end
        end

        # Run Sparkup
        class SparkupLine < EditTabCommand
            def execute
                doc.replace_line(doc.cursor_line) do |ltext|
                    spark = Sparkup.new
                    cmd = spark.getCmd
                    dir = "#{Sparkup.plugin_dir}/assets"
                    startLine = doc.cursor_offset

                    # Run the command
                    cmd =  "cd #{dir} && echo '#{ltext}' | #{cmd}"
                    resp = `#{cmd}`

                    # Set the cursor to the start of the line
                    # TODO: Add tab positions like snippets
                    doc.cursor_offset = startLine
                    resp
                end
            end
        end
    end
end
