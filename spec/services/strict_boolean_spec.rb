# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StrictBoolean do
  it 'passes real booleans through' do
    expect(described_class.cast(true)).to be(true)
    expect(described_class.cast(false)).to be(false)
  end

  it 'reads the spellings a query string or form sends, ignoring case and padding' do
    expect(%w[true T 1 yes Y on].map { |v| described_class.cast(v) }).to all(be(true))
    expect(%w[false F 0 no N off].map { |v| described_class.cast(" #{v} ") }).to all(be(false))
  end

  it 'returns nil for anything else, where ActiveModel would say true' do
    expect([nil, '', 'maybe', 'tru', '2'].map { |v| described_class.cast(v) }).to all(be_nil)
    expect(ActiveModel::Type::Boolean.new.cast('maybe')).to be(true)
  end
end
