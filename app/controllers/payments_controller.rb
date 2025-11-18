class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[ show edit update destroy ]

  # GET /payments or /payments.json
  def index
    @payments = Payment.order(created_at: :desc).page(params[:page]).per(5)
  end

  # GET /payments/1 or /payments/1.json
  def show
  end

  # GET /payments/new
  def new
    @payment = Payment.new
  end

  # GET /payments/1/edit
  def edit
  end

  # POST /payments or /payments.json
  def create
    @payment = Payment.new(payment_params)
    @payment.created_by = Current.user
    @payment.updated_by = Current.user

    respond_to do |format|
      if @payment.save
        format.html { redirect_to @payment, notice: "Payment was successfully created." }
        format.json { render :show, status: :created, location: @payment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payments/1 or /payments/1.json
  def update
    @payment.updated_by = Current.user
    respond_to do |format|
      if @payment.update(payment_params)
        format.html { redirect_to @payment, notice: "Payment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @payment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payments/1 or /payments/1.json
  def destroy
    if @payment.installment_payments.exists?
      respond_to do |format|
        format.html { redirect_to @payment, alert: "Cannot delete payment that has been applied to installments. This payment is already applied to #{@payment.installment_payments.count} installment(s).", status: :see_other }
        format.json { render json: { error: "Cannot delete payment that has been applied to installments" }, status: :unprocessable_entity }
      end
    else
      @payment.destroy!

      respond_to do |format|
        format.html { redirect_to payments_path, notice: "Payment was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment
      @payment = Payment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def payment_params
      params.expect(payment: [ :loan_id, :amount, :payment_date, :notes ])
    end
end
