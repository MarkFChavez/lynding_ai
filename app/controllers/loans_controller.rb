class LoansController < ApplicationController
  before_action :set_loan, only: %i[ show edit update destroy export_pdf export_csv ]

  # GET /loans or /loans.json
  def index
    @loans = Loan.order(start_date: :desc).page(params[:page]).per(5)
  end

  # GET /loans/1 or /loans/1.json
  def show
  end

  # GET /loans/new
  def new
    @loan = Loan.new
  end

  # GET /loans/1/edit
  def edit
  end

  # POST /loans or /loans.json
  def create
    @loan = Loan.new(loan_params)
    @loan.created_by = Current.user
    @loan.updated_by = Current.user

    respond_to do |format|
      if @loan.save
        format.html { redirect_to @loan, notice: "Loan was successfully created." }
        format.json { render :show, status: :created, location: @loan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @loan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /loans/1 or /loans/1.json
  def update
    @loan.updated_by = Current.user
    respond_to do |format|
      if @loan.update(loan_params)
        format.html { redirect_to @loan, notice: "Loan was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @loan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @loan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /loans/1 or /loans/1.json
  def destroy
    if @loan.payments.exists?
      respond_to do |format|
        format.html { redirect_to @loan, alert: "Cannot delete loan with payment history. #{@loan.payments.count} payment(s) recorded.", status: :see_other }
        format.json { render json: { error: "Cannot delete loan with payment history" }, status: :unprocessable_entity }
      end
    else
      @loan.destroy!

      respond_to do |format|
        format.html { redirect_to loans_path, notice: "Loan was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    end
  end

  # GET /loans/1/export_pdf
  def export_pdf
    pdf = LoanPdfExporter.new(@loan).generate
    send_data pdf.render,
      filename: "loan_#{@loan.id}_#{@loan.borrower.name.parameterize}_#{Date.current.strftime('%Y%m%d')}.pdf",
      type: 'application/pdf',
      disposition: 'attachment'
  end

  # GET /loans/1/export_csv
  def export_csv
    csv_data = LoanCsvExporter.new(@loan).generate
    send_data csv_data,
      filename: "loan_#{@loan.id}_#{@loan.borrower.name.parameterize}_#{Date.current.strftime('%Y%m%d')}.csv",
      type: 'text/csv',
      disposition: 'attachment'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_loan
      @loan = Loan.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def loan_params
      params.expect(loan: [ :borrower_id, :referral_agent_id, :amount, :interest_rate, :term_months, :start_date, :status ])
    end
end
