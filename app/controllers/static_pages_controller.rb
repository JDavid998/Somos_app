class StaticPagesController < ApplicationController
  def root
    @Hora_actual = Time.current
    @Hfecha = Time.current.strftime("%d/%m/%Y")
  end

  def somos
  end

  def tech
  end

end
