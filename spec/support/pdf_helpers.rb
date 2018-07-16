module PdfHelpers
  def get_fields_from_pdf(tempfile)
    pdftk = PdfForms.new(Cliver.detect('pdftk'))
    fields = pdftk.get_fields tempfile.path

    {}.tap do |fields_dict|
      fields.each do |field|
        fields_dict[field.name] = field.value
      end
    end
  end
end
