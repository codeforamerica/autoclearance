class PleaBargainClassifier
  def initialize(count:, event:)
    @count = count
    @event = event
  end

  def plea_bargain?
    count.subsection_of?(possible_plea_bargain_codes) && code_sections_in_cycle_are_potentially_eligible
  end

  def possible_plea_bargain?
    count.subsection_of?(possible_plea_bargain_codes) && cycle_contains_prop64_count
  end
  
  private
  
  attr_reader :count, :event

  def possible_plea_bargain_codes
    [
      'PC 32',
      'HS 11364',
      'HS 11366'
    ]
  end

  def code_sections_in_cycle_are_potentially_eligible
    unrejected_counts_for_event_cycle.all? do |count|
      count.subsection_of?(possible_plea_bargain_codes) || count.prop64_conviction?
    end
  end

  def unrejected_counts_for_event_cycle
    event.cycle_events.flat_map do |event|
      event.counts.reject do |count|
        count.disposition && count.disposition.type == 'prosecutor_rejected'
      end
    end
  end

  def cycle_contains_prop64_count
    unrejected_counts_for_event_cycle.any?(&:prop64_conviction?)
  end
end
