require 'gosu'

module ECS
 
  MILLISECOND = 0.001

  def self.make_sprite image, anchor={:x => 0.5, :y => 0.5}
    {:image => image, :anchor => anchor}
  end

  class Engine

    def initialize
      @last_time = Gosu::milliseconds
      @time = 0

      @entity_num = 0
      @systems = {:update => {}, :draw => {}}
      @input_systems = {:up => {}, :down => {}}
      @entities = {}
      @entities_new = {}
      @input_state = {}
    end

    def system type, name, node, &block
      @systems[type][name] = [node, block]
      self
    end

    def remove_system type, name
      @systems[type].delete name
      self
    end

    def input_system type, name, node, &block
      @input_systems[type][name] = [node, block]
      self
    end

    def remove_input_system type, name
      @input_systems[type].delete name
      self
    end

    def add_entity entity
      @entities[@entity_num] = entity
      @entities_new[@entity_num] ||= entity
      @entity_num += 1
      self
    end

    def remove_entity entity
      entity[:delete] = true
      self
    end

    def each_entity n
      @entities.each do |i, e|
        if matches? e, n
          yield e
        end
      end
    end

    def button_down id
      @entities.each do |i, e|
        each_with_entity_input @input_systems[:down], i, e, id
      end
      @input_state[id] = true
    end

    def button_up id
      @entities.each do |i, e|
        each_with_entity_input @input_systems[:up], i, e, id
      end
      @input_state[id] = false
    end

    def update
      new_time = Gosu::milliseconds
      dt = (new_time-@last_time).to_f*MILLISECOND
      @time += dt
      @last_time = new_time

      @entities.each do |i, e|
        each_with_entity_new @systems[:update], i, e, dt
        @entities_new[i].delete if e[:delete]
      end

      temp = @entities
      @entities = @entities_new
      @entities_new = temp

      @input_state.clear
    end

    def draw
      @entities.each do |i, e|
        each_with_entity @systems[:draw], i, e
      end
    end

    private

      def matches? entity, node
        node.each do |c|
          return false if !entity.include?(c)
        end
        true
      end

      def each_with_entity sys, i, e
        sys.each_value do |n, s|
          if matches? e, n
            s.call e
          end
        end
      end

      def each_with_entity_input sys, i, e, id
        sys.each_value do |n, s|
          if matches? e, n
            s.call id, e
          end
        end
      end

      def each_with_entity_new sys, i, e, dt
        sys.each_value do |n, s|
          if matches? e, n
            @entities_new[i].merge(s.call(dt, @time, e.select { |k,v| n.include? k }))
          end
        end
      end

  end

end