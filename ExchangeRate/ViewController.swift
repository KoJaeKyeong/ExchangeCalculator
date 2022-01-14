//
//  ViewController.swift
//  ExchangeRate
//
//  Created by Jae Kyeong Ko on 2022/01/10.
//

import UIKit

final class ViewController: UIViewController {
    @IBOutlet private weak var countryTextField: UITextField!
    @IBOutlet private weak var moneyTextField: UITextField!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var resultLabel: UILabel!
    @IBOutlet private weak var currencyLabel: UILabel!
    
    private let countries = ["한국(KRW)", "일본(JPY)", "필리핀(PHP)"]
    private let pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }
    
    private func configure() {
        self.configureCountryTextField()
        self.configurePickerView()
        self.configureCountryPickerToolbar()
        self.configureMoneyToolbar()
    }
    
    private func configureCountryTextField() {
        self.countryTextField.tintColor = .clear
    }
    
    private func callAPI() {
        var apiKey: String {
            get {
                guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else { return "can't get file path" }
                let plist = NSDictionary(contentsOfFile: filePath)
                guard let value = plist?.object(forKey: "apiKey") as? String else { return "fail to get APIKEY" }
                return value
            }
        }
        
        guard let url = URL(string: "http://api.currencylayer.com/live?access_key=\(apiKey)&currencies=KRW,JPY,PHP") else { return }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil,
                  let data = data,
                  let response = response as? HTTPURLResponse,
                  200...299 ~= response.statusCode,
                  let self = self else { return }

            do {
                let exchangeResponse = try JSONDecoder().decode(ExchangeResponse.self, from: data)
                let quotes = exchangeResponse.quotes
                
                DispatchQueue.main.async {
                    self.checkTextFieldIsEmpty()
                    guard let money = Double(self.moneyTextField.text ?? "0") else { return }
                    self.dateLabel.text = self.timestampToDateString(timestamp: exchangeResponse.timestamp)
                    
                    if self.countryTextField.text == "한국(KRW)" {
                        self.currencyLabel.text = "\(self.withCommaString(num: quotes.usdkrw)) KRW / USD"
                        self.resultLabel.text = "수취금액은 \(self.withCommaString(num: quotes.usdkrw * money)) KRW 입니다."
                    } else if self.countryTextField.text == "일본(JPY)" {
                        self.currencyLabel.text = "\(self.withCommaString(num: quotes.usdjpy)) JPY / USD"
                        self.resultLabel.text = "수취금액은 \(self.withCommaString(num: quotes.usdkrw * money)) JPY 입니다."
                    } else if self.countryTextField.text == "필리핀(PHP)" {
                        self.currencyLabel.text = "\(self.withCommaString(num: quotes.usdphp)) PHP / USD"
                        self.resultLabel.text = "수취금액은 \(self.withCommaString(num: quotes.usdphp * money)) PHP 입니다."
                    }
                    
                    if money < 0 || money > 10000 {
                        self.showAlert(message: "송금액이 바르지 않습니다.")
                    }
                }
            } catch let error {
                print("error: ", error)
            }
        }.resume()
    }
    
    private func configurePickerView() {
        self.pickerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 230)
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        self.countryTextField.inputView = pickerView
    }
    
    private func configureCountryPickerToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTappedCountryDoneButton))
        toolbar.setItems([doneButton], animated: false)
        self.countryTextField.inputAccessoryView = toolbar
    }
    
    private func configureMoneyToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTappedMoneyDoneButton))
        toolbar.setItems([doneButton], animated: false)
        self.moneyTextField.inputAccessoryView = toolbar
    }
    
    private func withCommaString(num: Double) -> String {
        let numberFormatter = NumberFormatter()
        let demicalPointSecond = Double(String(format: "%.2f", num)) ?? 0
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: demicalPointSecond)) ?? ""
    }
    
    private func timestampToDateString(timestamp: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return dateFormatter.string(from: date)
    }
    
    private func checkTextFieldIsEmpty() {
        if self.moneyTextField.hasText == false && self.countryTextField.hasText == false {
            self.showAlert(message: "국가와 송금액을 입력해주세요.")
        } else if self.countryTextField.hasText == false {
            self.showAlert(message: "국가를 선택해주세요.")
        } else if self.moneyTextField.hasText == false {
            self.showAlert(message: "송금액을 입력해주세요.")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: false)
        }
        alert.addAction(confirmAction)
        present(alert, animated: false)
    }
    
    @objc private func didTappedCountryDoneButton() {
        let row = self.pickerView.selectedRow(inComponent: 0)
        self.pickerView.selectRow(row, inComponent: 0, animated: false)
        self.countryTextField.text = self.countries[row]
        self.countryTextField.resignFirstResponder()
    }
    
    @objc private func didTappedMoneyDoneButton() {
        self.moneyTextField.resignFirstResponder()
    }
    
    @IBAction private func calculate(_ sender: Any) {
        self.callAPI()
    }
}

// MARK: -UIPickerViewDataSource, UIPickerViewDelegate 구현
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.countries[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.countryTextField.text = self.countries[row]
    }
}
