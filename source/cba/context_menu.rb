# Cut By Altitude extension for SketchUp 2017 or newer.
# Copyright: © 2019 Samuel Tallet <samuel.tallet arobase gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3.0 of the License, or
# (at your option) any later version.
# 
# If you release a modified version of this program TO THE PUBLIC,
# the GPL requires you to MAKE THE MODIFIED SOURCE CODE AVAILABLE
# to the program's users, UNDER THE GPL.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# Get a copy of the GPL here: https://www.gnu.org/licenses/gpl.html

raise 'The CBA plugin requires at least Ruby 2.2.0 or SketchUp 2017.'\
  unless RUBY_VERSION.to_f >= 2.2 # SketchUp 2017 includes Ruby 2.2.4.

require 'sketchup'
require 'cba/cut'

# CBA plugin namespace.
module CBA

  # Connects CBA plugin context menu to SketchUp UI.
  class ContextMenu

    # Adds CBA plugin... to SketchUp context menu.
    def initialize

      UI.add_context_menu_handler { |context_menu|

        selected_entity = Sketchup.active_model.selection.first

        if selected_entity.is_a?(Sketchup::Group)

          context_menu.add_item('✄ ' + TRANSLATE[NAME]) {

            parameters = UI.inputbox(

              [TRANSLATE['Altitude in meters'] + ' '], # Prompt
              [1], # Default
              TRANSLATE[NAME] # Title

            )

            # Escapes if user cancelled operation.
            return if parameters == false

            Cut.new(selected_entity, parameters[0].to_i)

          }

        end

      }

    end

  end

end
